import json
import hashlib
import os
import socket
import sqlite3
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DIRECT_OPENER = urllib.request.build_opener(urllib.request.ProxyHandler({}))


def test_fcm_batching():
    import importlib.util
    spec = importlib.util.spec_from_file_location("antam_backend_test", ROOT / "app.py")
    app = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(app)

    class FakeMessage:
        def __init__(self, **kwargs): self.__dict__.update(kwargs)

    class FakeResponse:
        def __init__(self, count): self.success_count=count; self.failure_count=0

    class FakeMessaging:
        Notification = FakeMessage
        MulticastMessage = FakeMessage
        batches = []
        @classmethod
        def send_each_for_multicast(cls, message):
            cls.batches.append(message)
            return FakeResponse(len(message.tokens))

    app.FCM = FakeMessaging
    result = app.send_fcm([f"device-{i}" for i in range(501)], "Title", "Body", {"referenceId": 9})
    assert result == {"configured": True, "sentCount": 501, "failureCount": 0}
    assert [len(message.tokens) for message in FakeMessaging.batches] == [500, 1]
    assert FakeMessaging.batches[0].data == {"referenceId": "9"}


def request(url, method="GET", data=None, token=None):
    headers = {"Content-Type": "application/json"}
    if token: headers["Authorization"] = "Bearer " + token
    body = json.dumps(data).encode() if data is not None else None
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with DIRECT_OPENER.open(req, timeout=3) as resp: return resp.status, json.load(resp)
    except urllib.error.HTTPError as exc: return exc.code, json.loads(exc.read())


def multipart_request(url, fields, files, token=None):
    boundary = "----AnTamSmokeBoundary"
    chunks = []
    for name, value in fields.items():
        chunks.extend([f"--{boundary}\r\nContent-Disposition: form-data; name=\"{name}\"\r\n\r\n{value}\r\n".encode()])
    for name, filename, content_type, content in files:
        chunks.extend([f"--{boundary}\r\nContent-Disposition: form-data; name=\"{name}\"; filename=\"{filename}\"\r\nContent-Type: {content_type}\r\n\r\n".encode(), content, b"\r\n"])
    chunks.append(f"--{boundary}--\r\n".encode())
    headers = {"Content-Type": f"multipart/form-data; boundary={boundary}"}
    if token: headers["Authorization"] = "Bearer " + token
    req = urllib.request.Request(url, data=b"".join(chunks), headers=headers, method="POST")
    try:
        with DIRECT_OPENER.open(req, timeout=3) as resp: return resp.status, json.load(resp)
    except urllib.error.HTTPError as exc: return exc.code, json.loads(exc.read())


def main():
    test_fcm_batching()
    with tempfile.TemporaryDirectory(prefix="antam-api-test-") as tmp:
        with socket.socket() as sock:
            sock.bind(("127.0.0.1", 0)); port = sock.getsockname()[1]
        env = dict(os.environ, PHARMA_DB=str(Path(tmp) / "test.sqlite3"), PHARMA_UPLOADS=str(Path(tmp) / "uploads"), FIREBASE_SERVICE_ACCOUNT_FILE="", HOST="127.0.0.1", PORT=str(port))
        proc = subprocess.Popen([sys.executable, str(ROOT / "app.py")], cwd=ROOT, env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        base = f"http://127.0.0.1:{port}/api/v1"
        try:
            for _ in range(50):
                try:
                    status, health = request(base + "/health")
                    if status == 200: break
                except Exception: time.sleep(.1)
            assert status == 200 and health["data"]["database"] == "SQLite"
            legacy_hash = hashlib.pbkdf2_hmac("sha256", b"12345678", b"antam-local-v1", 180_000).hex()
            db = sqlite3.connect(Path(tmp) / "test.sqlite3")
            try:
                db.execute("UPDATE users SET passwordHash=? WHERE id='u-admin'", (legacy_hash,))
                db.commit()
            finally:
                db.close()
            status, login = request(base + "/auth/login", "POST", {"username":"ductri", "password":"12345678"})
            assert status == 200 and "ADMIN" in login["data"]["user"]["roles"] and "passwordHash" not in login["data"]["user"]
            db = sqlite3.connect(Path(tmp) / "test.sqlite3")
            try:
                verified_hash = db.execute("SELECT passwordHash FROM users WHERE id='u-admin'").fetchone()[0]
            finally:
                db.close()
            assert verified_hash == legacy_hash
            status, rejected_login = request(base + "/auth/login", "POST", {"username":"ductri", "password":"wrong-password"})
            assert status == 401 and "không đúng" in rejected_login["message"]
            token = login["data"]["accessToken"]
            status, me = request(base + "/auth/me", token=token)
            assert status == 200 and me["data"]["email"] == "ductri@antam.local"
            status, products = request(base + "/products?page=0&size=20")
            assert status == 200 and products["data"]["totalElements"] >= 8
            status, categories = request(base + "/categories")
            assert status == 200 and len(categories["data"]) >= 4
            status, pharmacies = request(base + "/pharmacies")
            assert status == 200 and len(pharmacies["data"]) == 2
            status, stock = request(base + "/inventory/products/p-vitc")
            assert status == 200 and len(stock["data"]) == 2
            status, admin_stock = request(base + "/inventory/admin?productId=p-vitc&pharmacyId=pharmacy-quan-1", token=token)
            assert status == 200 and len(admin_stock["data"]) == 1
            status, changed_stock = request(base + "/inventory/admin/"+admin_stock["data"][0]["id"]+"/quantity", "PUT", {"quantity":7}, token)
            assert status == 200 and changed_stock["data"]["quantity"] == 7
            status, new_category = request(base + "/categories", "POST", {"name":"Test category","slug":"test-category","isActive":True}, token)
            assert status == 201
            status, updated_category = request(base + "/categories/"+new_category["data"]["id"], "PUT", {"name":"Test category updated","slug":"test-category","isActive":True}, token)
            assert status == 200 and updated_category["data"]["name"] == "Test category updated"
            status, new_brand = request(base + "/brands", "POST", {"name":"Test brand","country":"Vietnam","isActive":True}, token)
            assert status == 201 and new_brand["data"]["country"] == "Vietnam"
            status, updated_brand = request(base + "/brands/"+new_brand["data"]["id"], "PUT", {"name":"Updated brand","country":"Vietnam","isActive":True}, token)
            assert status == 200 and updated_brand["data"]["name"] == "Updated brand"
            status, new_product = request(base + "/products", "POST", {"name":"Test product","sku":"TEST-001","slug":"test-product","categoryId":new_category["data"]["id"],"unit":"hộp","price":10000}, token)
            assert status == 201 and new_product["data"]["price"] == 10000
            status, updated_product = request(base + "/products/"+new_product["data"]["id"], "PUT", {"name":"Test product updated","sku":"TEST-001","slug":"test-product","categoryId":new_category["data"]["id"],"unit":"hộp","price":15000}, token)
            assert status == 200 and updated_product["data"]["price"] == 15000
            status, product_by_slug = request(base + "/products/slug/test-product")
            assert status == 200 and product_by_slug["data"]["id"] == new_product["data"]["id"]
            status, image_added = multipart_request(base + "/products/"+new_product["data"]["id"]+"/images", {}, [("files", "product.webp", "image/webp", b"product-image")], token)
            assert status == 200
            status, product_detail = request(base + "/products/"+new_product["data"]["id"])
            assert status == 200 and len(product_detail["data"]["images"]) == 1
            status, vouchers = request(base + "/vouchers")
            assert status == 200 and vouchers["data"][0]["code"] == "CHAOMUNG10"
            status, applied = request(base + "/vouchers/apply", "POST", {"code":"CHAOMUNG10","orderAmount":200000})
            assert status == 200 and applied["data"]["discountAmount"] == 20000
            status, voucher = request(base + "/admin/vouchers", "POST", {"code":"SMOKE5","name":"Smoke test","discountType":"PERCENTAGE","discountValue":5,"minOrderAmount":0,"isActive":True}, token)
            assert status == 201 and voucher["data"]["code"] == "SMOKE5"
            status, created = request(base + "/reviews", "POST", {"productId":"p-vitc","rating":5,"comment":"test"}, token)
            assert status == 201 and created["data"]["rating"] == 5
            status, product_reviews = request(base + "/reviews/products/p-vitc?page=0&size=10")
            assert status == 200 and product_reviews["data"]["totalElements"] == 1
            status, cart_item = request(base + "/cart/items", "POST", {"productId":"p-vitc","quantity":2}, token)
            assert status == 201 and cart_item["data"]["totalAmount"] == 130000 and cart_item["data"]["items"][0]["quantity"] == 2
            status, cart = request(base + "/cart", token=token)
            assert status == 200 and cart["data"]["totalItems"] == 2
            status, address = request(base + "/users/addresses", "POST", {"receiverName":"DucTri","receiverPhone":"0900000001","province":"TP.HCM","district":"Quận 1","ward":"Bến Nghé","detailAddress":"12 Nguyễn Huệ"}, token)
            assert status == 201 and address["data"]["isDefault"] is True
            status, order = request(base + "/orders", "POST", {"addressId":address["data"]["id"],"pharmacyId":"pharmacy-quan-1","paymentMethod":"COD"}, token)
            assert status == 201 and order["data"]["orderStatus"] == "PENDING" and order["data"]["totalAmount"] == 130000
            status, my_orders = request(base + "/orders/my-orders?page=0&size=10", token=token)
            assert status == 200 and my_orders["data"]["totalElements"] == 1
            status, changed_order = request(base + "/orders/admin/"+order["data"]["id"]+"/status", "PUT", {"status":"CONFIRMED"}, token)
            assert status == 200 and changed_order["data"]["orderStatus"] == "CONFIRMED"
            status, cancelled_order = request(base + "/orders/"+order["data"]["id"]+"/cancel", "PUT", {"reason":"Smoke test"}, token)
            assert status == 200 and cancelled_order["data"]["orderStatus"] == "CANCELLED"
            status, restored_stock = request(base + "/inventory/products/p-vitc")
            assert status == 200 and next(x["quantity"] for x in restored_stock["data"] if x["pharmacyId"]=="pharmacy-quan-1") == 7
            status, cart_again = request(base + "/cart/items", "POST", {"productId":"p-vitc","quantity":1}, token)
            assert status == 201
            status, paid_order = request(base + "/orders", "POST", {"addressId":address["data"]["id"],"pharmacyId":"pharmacy-quan-1","paymentMethod":"COD"}, token)
            assert status == 201
            status, payment = request(base + "/payments", "POST", {"orderId":paid_order["data"]["id"],"paymentMethod":"COD"}, token)
            assert status == 201 and payment["data"]["amount"] == 65000
            status, paid = request(base + "/payments/"+payment["data"]["id"]+"/status", "PUT", {"paymentStatus":"PAID","transactionCode":"LOCAL-TEST"}, token)
            assert status == 200 and paid["data"]["paymentStatus"] == "PAID"
            status, completed_order = request(base + "/orders/admin/"+paid_order["data"]["id"]+"/status", "PUT", {"status":"COMPLETED"}, token)
            assert status == 200 and completed_order["data"]["orderStatus"] == "COMPLETED"
            status, updated_stock = request(base + "/inventory/products/p-vitc")
            assert status == 200 and next(x["quantity"] for x in updated_stock["data"] if x["pharmacyId"]=="pharmacy-quan-1") == 6
            status, my_payments = request(base + "/payments/my-payments", token=token)
            assert status == 200 and len(my_payments["data"]) == 1
            status, profile = request(base + "/users/profile", token=token)
            assert status == 200 and profile["data"]["username"] == "ductri"
            status, address_list = request(base + "/users/addresses", token=token)
            assert status == 200 and len(address_list["data"]) == 1
            status, users = request(base + "/admin/users", token=token)
            assert status == 200 and len(users["data"]) == 3 and "passwordHash" not in users["data"][0]
            status, dashboard = request(base + "/admin/dashboard/overview", token=token)
            assert status == 200 and dashboard["data"]["totalUsers"] == 3 and dashboard["data"]["totalOrders"] == 2 and dashboard["data"]["totalRevenue"] == 65000
            status, order_stats = request(base + "/admin/dashboard/order-status", token=token)
            assert status == 200 and any(x["status"]=="CANCELLED" and x["count"]==1 for x in order_stats["data"])
            status, revenue_stats = request(base + "/admin/dashboard/revenue/last-7-days", token=token)
            assert status == 200 and len(revenue_stats["data"]) == 7
            status, blocked = request(base + "/admin/users/u-customer/block", "PUT", {}, token)
            assert status == 200 and blocked["data"]["status"] == "BLOCKED"
            status, unlocked = request(base + "/admin/users/u-customer/unlock", "PUT", {}, token)
            assert status == 200 and unlocked["data"]["status"] == "ACTIVE"
            status, logs = request(base + "/admin/activity-logs?page=0&size=20", token=token)
            assert status == 200 and logs["data"]["totalElements"] >= 4 and logs["data"]["content"][0]["action"].startswith("USER_")
            status, token_data = request(base + "/device-tokens", "POST", {"token":"sample-fcm-token","platform":"android"}, token)
            assert status == 201 and token_data["data"]["active"] is True
            status, sent = request(base + "/admin/notifications/send", "POST", {"sendToAllCustomers":True,"title":"Thông báo","content":"Chương trình mới","type":"GENERAL"}, token)
            assert status == 201 and sent["data"]["sentCount"] >= 1 and sent["data"]["pushConfigured"] is False and sent["data"]["pushSentCount"] == 0
            status, customer_login = request(base + "/auth/login", "POST", {"username":"khachhang","password":"12345678"})
            customer_token=customer_login["data"]["accessToken"]
            status, unread = request(base + "/notifications/unread-count", token=customer_token)
            assert status == 200 and unread["data"] == 1
            status, prescription = request(base + "/prescriptions", "POST", {"patientName":"Khách hàng mẫu","imageUrls":["http://localhost/sample.jpg"]}, customer_token)
            assert status == 201 and prescription["data"]["status"] == "PENDING"
            status, staff_login = request(base + "/auth/login", "POST", {"username":"ngoctien","password":"12345678"})
            staff_token=staff_login["data"]["accessToken"]
            status, reviewed_rx = request(base + "/prescriptions/admin/"+prescription["data"]["id"]+"/review", "PUT", {"status":"APPROVED","pharmacistNote":"Đã kiểm tra"}, staff_token)
            assert status == 200 and reviewed_rx["data"]["status"] == "APPROVED"
            status, uploaded_rx = multipart_request(base + "/prescriptions/upload", {"patientName":"Khách hàng mẫu"}, [("files", "prescription.jpg", "image/jpeg", b"demo-image")], customer_token)
            assert status == 201 and uploaded_rx["data"]["images"][0]["imageUrl"].endswith(".jpg")
            with DIRECT_OPENER.open(uploaded_rx["data"]["images"][0]["imageUrl"], timeout=3) as image_response:
                assert image_response.status == 200 and image_response.read() == b"demo-image"
            status, upload = multipart_request(base + "/files/upload", {}, [("file", "avatar.png", "image/png", b"demo-image")], customer_token)
            assert status == 201 and upload["data"]["size"] == 10
            status, otp_requested = request(base + "/auth/forgot-password", "POST", {"username":"khachhang@antam.local"})
            assert status == 200 and "123456" in otp_requested["data"]["message"]
            status, verified = request(base + "/auth/verify-forgot-password-otp", "POST", {"username":"khachhang@antam.local","otpCode":"123456"})
            assert status == 200 and verified["data"]["verified"] is True
            status, reset = request(base + "/auth/reset-password-with-otp", "POST", {"username":"khachhang@antam.local","otpCode":"123456","newPassword":"NewPass123!","confirmPassword":"NewPass123!"})
            assert status == 200
            status, relogin = request(base + "/auth/login", "POST", {"username":"khachhang","password":"NewPass123!"})
            assert status == 200
            print("PASS: auth/reset, profile/addresses, catalog CRUD, pharmacy/inventory, voucher, review, cart/order/payment, prescriptions/uploads, admin/dashboard/activity logs, FCM batching, device tokens and notifications")
        finally:
            proc.terminate(); proc.wait(timeout=5)


if __name__ == "__main__": main()
