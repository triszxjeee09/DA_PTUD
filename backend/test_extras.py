"""Test tích hợp cho các tính năng mở rộng (extras.py). Chạy: python backend/test_extras.py"""
import os
import socket
import subprocess
import sys
import tempfile
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path

from urllib.parse import quote

from test_api import multipart_request, request

ROOT = Path(__file__).resolve().parent


def login(base, username):
    status, body = request(base + "/auth/login", "POST", {"username": username, "password": "12345678"})
    assert status == 200, body
    return body["data"]["accessToken"]


def main():
    with tempfile.TemporaryDirectory(prefix="antam-extras-") as tmp:
        with socket.socket() as sock:
            sock.bind(("127.0.0.1", 0))
            port = sock.getsockname()[1]
        env = dict(os.environ, PHARMA_DB=str(Path(tmp) / "t.sqlite3"), PHARMA_UPLOADS=str(Path(tmp) / "up"),
                   FIREBASE_SERVICE_ACCOUNT_FILE="", HOST="127.0.0.1", PORT=str(port))
        proc = subprocess.Popen([sys.executable, str(ROOT / "app.py")], cwd=ROOT, env=env,
                                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        base = f"http://127.0.0.1:{port}/api/v1"
        try:
            for _ in range(60):
                try:
                    if request(base + "/health")[0] == 200:
                        break
                except Exception:
                    time.sleep(.1)
            admin, staff, cust = login(base, "ductri"), login(base, "ngoctien"), login(base, "khachhang")

            # ---- danh mục theo tài liệu: 6 nhóm + dữ liệu chi tiết sản phẩm
            _, cats = request(base + "/categories")
            names = {c["name"] for c in cats["data"]}
            assert {"Thiết bị y tế", "Mẹ và bé"} <= names, names
            _, detail = request(base + "/products/p-paracetamol")
            d = detail["data"]
            assert d["ingredients"] and d["dosage"] and d["targetAudience"] and d["inStock"] is True and "ratingAverage" in d

            # ---- tìm kiếm không dấu / theo triệu chứng / hoạt chất / nhà sản xuất + bộ lọc
            def search(qs):
                s, b = request(base + "/products?size=50&" + qs)
                assert s == 200
                return {x["id"] for x in b["data"]["content"]}
            assert "p-paracetamol" in search("keyword=dau%20dau")          # "đau đầu" (triệu chứng, không dấu)
            assert "p-paracetamol" in search("keyword=paracetamol")        # hoạt chất
            assert "p-sunscreen" in search("keyword=Sanofi")               # nhà sản xuất
            assert search("dosageForm=siro") == {"p-cough"}
            assert "p-mask" in search("maxPrice=50000") and "p-bp-monitor" not in search("maxPrice=50000")
            assert "p-vitd-baby" in search("targetAudience=tre%20so%20sinh")
            _, asc = request(base + "/products?size=50&sort=price_asc")
            prices = [x["price"] for x in asc["data"]["content"]]
            assert prices == sorted(prices)

            # ---- yêu thích
            s, _ = request(base + "/favorites", "POST", {"productId": "p-vitc"}, cust)
            assert s == 201
            _, favs = request(base + "/favorites", token=cust)
            assert [x["id"] for x in favs["data"]] == ["p-vitc"] and favs["data"][0]["isFavorite"] is True
            _, ids = request(base + "/favorites/ids", token=cust)
            assert ids["data"] == ["p-vitc"]
            request(base + "/favorites/p-vitc", "DELETE", token=cust)
            _, favs = request(base + "/favorites", token=cust)
            assert favs["data"] == []
            assert request(base + "/favorites")[0] == 401

            # ---- nhắc uống thuốc + đánh dấu đã uống
            s, rem = request(base + "/reminders", "POST", {"id": "rem-local-1", "medicineName": "Paracetamol 500mg", "dosage": "1 viên",
                                                          "times": ["08:00", "20:30"], "repeat": "DAILY"}, cust)
            assert s == 201 and rem["data"]["times"] == ["08:00", "20:30"]
            assert request(base + "/reminders", "POST", {"medicineName": "X", "times": ["25:99"]}, cust)[0] == 400
            s, log = request(base + "/reminders/rem-local-1/logs", "POST", {"date": "2026-11-20", "time": "08:00", "taken": True}, cust)
            assert s == 201 and log["data"]["taken"] is True
            _, logs = request(base + "/reminders/logs?from=2026-11-01", token=cust)
            assert len(logs["data"]) == 1
            _, mine = request(base + "/reminders", token=cust)
            assert len(mine["data"]) == 1
            _, other = request(base + "/reminders", token=admin)
            assert other["data"] == []  # người khác không thấy lịch của khách

            # ---- hồ sơ sức khỏe gia đình
            _, members = request(base + "/health/members", token=cust)
            assert len(members["data"]) == 1 and members["data"][0]["relation"] == "SELF"
            s, mom = request(base + "/health/members", "POST", {"name": "Mẹ", "relation": "MOTHER", "allergies": "Penicillin"}, cust)
            assert s == 201
            s, metric = request(base + f"/health/members/{mom['data']['id']}/metrics", "POST",
                                {"type": "BLOOD_PRESSURE", "value": 150, "value2": 95, "unit": "mmHg"}, cust)
            assert s == 201
            _, ms = request(base + f"/health/members/{mom['data']['id']}/metrics?type=BLOOD_PRESSURE", token=cust)
            assert len(ms["data"]) == 1
            assert request(base + f"/health/members/{members['data'][0]['id']}", "DELETE", token=cust)[0] == 409

            # ---- giỏ hàng: mọi thao tác trả về giỏ đầy đủ; + / - ; gộp cùng sản phẩm; xóa giỏ
            s, c1 = request(base + "/cart/items", "POST", {"productId": "p-paracetamol", "quantity": 2}, staff)
            assert s == 201 and c1["data"]["totalItems"] == 2 and len(c1["data"]["items"]) == 1
            s, c2 = request(base + "/cart/items", "POST", {"productId": "p-paracetamol", "quantity": 1}, staff)
            assert len(c2["data"]["items"]) == 1 and c2["data"]["totalItems"] == 3          # cộng dồn, không tạo dòng thứ hai
            request(base + "/cart/items", "POST", {"productId": "p-saline", "quantity": 1}, staff)
            item = c2["data"]["items"][0]["id"]
            s, c3 = request(base + f"/cart/items/{item}/increase", "PUT", token=staff)
            assert s == 200 and c3["data"]["totalItems"] == 5 and c3["data"]["items"][0]["quantity"] == 4
            s, c4 = request(base + f"/cart/items/{item}/decrease", "PUT", token=staff)
            assert c4["data"]["items"][0]["quantity"] == 3
            s, c5 = request(base + f"/cart/items/{item}", "PUT", {"quantity": 10}, staff)
            assert c5["data"]["items"][0]["quantity"] == 10 and c5["data"]["items"][0]["totalPrice"] == c5["data"]["items"][0]["unitPrice"] * 10
            assert request(base + f"/cart/items/{item}/increase", "PUT", token=admin)[0] == 404   # không sửa giỏ của người khác
            assert request(base + "/cart/items", "POST", {"productId": "khong-ton-tai"}, staff)[0] == 404
            s, c6 = request(base + "/cart", "DELETE", token=staff)
            assert s == 200 and c6["data"]["items"] == [] and request(base + "/cart", token=staff)[1]["data"]["totalItems"] == 0

            # ---- đơn hàng → hoàn tất → điểm thưởng → đổi voucher → áp dụng
            _, addr = request(base + "/users/addresses", "POST", {"receiverName": "Khách", "receiverPhone": "0900000003", "province": "TP.HCM",
                                                                  "district": "Quận 1", "ward": "Bến Nghé", "detailAddress": "1 Lê Lợi"}, cust)
            request(base + "/cart/items", "POST", {"productId": "p-vitc", "quantity": 3}, cust)  # 195.000đ
            _, order = request(base + "/orders", "POST", {"addressId": addr["data"]["id"], "pharmacyId": "pharmacy-quan-1", "paymentMethod": "BANK_TRANSFER"}, cust)
            oid = order["data"]["id"]
            _, qr = request(base + f"/payments/bank-qr?orderId={oid}", token=cust)
            assert qr["data"]["amount"] == 195000 and qr["data"]["qrUrl"].startswith("https://img.vietqr.io/")
            _, st = request(base + "/orders/admin/" + oid + "/status", "PUT", {"status": "DELIVERED"}, admin)
            assert st["data"]["orderStatusLabel"] == "Đã giao"   # trạng thái mà app Flutter dùng
            _, loy = request(base + "/loyalty", token=cust)
            assert loy["data"]["points"] == 195 and loy["data"]["tier"] == "BRONZE" and loy["data"]["history"][0]["type"] == "EARN"
            # chuyển DELIVERED -> COMPLETED không cộng điểm lần nữa
            request(base + "/orders/admin/" + oid + "/status", "PUT", {"status": "COMPLETED"}, admin)
            assert request(base + "/loyalty", token=cust)[1]["data"]["points"] == 195
            s, red = request(base + "/loyalty/redeem", "POST", {"rewardId": "reward-10k"}, cust)
            assert s == 201 and red["data"]["summary"]["points"] == 95
            code = red["data"]["voucher"]["code"]
            s, applied = request(base + "/vouchers/apply", "POST", {"code": code, "orderAmount": 100000}, cust)
            assert s == 200 and applied["data"]["discountAmount"] == 10000
            assert request(base + "/loyalty/redeem", "POST", {"rewardId": "reward-50k"}, cust)[0] == 409  # không đủ điểm
            # voucher cá nhân không lộ cho người khác
            _, vs = request(base + "/vouchers", token=staff)
            assert code not in {v["code"] for v in vs["data"]}
            # admin cộng/trừ điểm
            s, adj = request(base + "/admin/users/u-customer/points", "POST", {"delta": 50, "reason": "Quà tri ân"}, admin)
            assert s == 200 and adj["data"]["points"] == 145
            assert request(base + "/admin/users/u-customer/points", "POST", {"delta": -999, "reason": "x"}, admin)[0] == 409
            assert request(base + "/admin/users/u-customer/points", "POST", {"delta": 5, "reason": "x"}, cust)[0] == 403
            _, uo = request(base + "/admin/users/u-customer/orders", token=admin)
            assert uo["data"]["totalElements"] == 1

            # ---- mua lại, hóa đơn, thuốc thường dùng, hoàn tiền
            s, re_ = request(base + f"/orders/{oid}/reorder", "POST", token=cust)
            assert s == 200 and re_["data"]["addedCount"] == 1
            _, cart = request(base + "/cart", token=cust)
            assert cart["data"]["totalItems"] == 3
            s, adm = request(base + f"/orders/admin/{oid}", token=admin)
            assert s == 200 and adm["data"]["orderCode"] and request(base + f"/orders/admin/{oid}", token=cust)[0] == 403
            _, inv = request(base + f"/orders/{oid}/invoice", token=cust)
            assert inv["data"]["total"] == 195000 and inv["data"]["invoiceNumber"].startswith("HD")
            assert request(base + f"/orders/{oid}/invoice", token=staff)[0] == 200   # nhân viên xem được
            _, freq = request(base + "/orders/frequent-products", token=cust)
            assert freq["data"][0]["product"]["id"] == "p-vitc" and freq["data"][0]["timesPurchased"] == 1
            assert request(base + f"/orders/admin/{oid}/refund", "POST", {"reason": "Khách trả hàng"}, cust)[0] == 403
            s, ref = request(base + f"/orders/admin/{oid}/refund", "POST", {"reason": "Khách trả hàng"}, admin)
            assert s == 409  # COMPLETED + BANK_TRANSFER chưa PAID -> không hoàn tiền
            _, pay = request(base + "/payments", "POST", {"orderId": oid, "paymentMethod": "BANK_TRANSFER"}, cust)
            # khách KHÔNG được tự đánh dấu đã thanh toán; chỉ admin xác nhận khi đã nhận tiền
            assert request(base + f"/payments/{pay['data']['id']}/status", "PUT", {"paymentStatus": "PAID"}, cust)[0] == 403
            assert request(base + f"/orders/admin/{oid}/confirm-payment", "POST", {}, cust)[0] == 403
            s, cf = request(base + f"/orders/admin/{oid}/confirm-payment", "POST", {"transactionCode": "T1"}, admin)
            assert s == 200 and cf["data"]["paymentStatus"] == "PAID"
            assert request(base + f"/orders/admin/{oid}/confirm-payment", "POST", {}, admin)[0] == 409
            s, ref = request(base + f"/orders/admin/{oid}/refund", "POST", {"reason": "Khách trả hàng"}, admin)
            assert s == 200 and ref["data"]["paymentStatus"] == "REFUNDED"
            assert request(base + f"/orders/admin/{oid}/refund", "POST", {}, admin)[0] == 409

            # ---- đánh giá: chỉ người đã mua, ảnh, lọc sao, phản hồi nhà thuốc
            assert request(base + "/reviews", "POST", {"productId": "p-saline", "rating": 5}, cust)[0] == 403
            s, rv = request(base + "/reviews", "POST", {"productId": "p-vitc", "rating": 4, "comment": "Ổn", "imageUrls": ["http://x/y.jpg"]}, cust)
            assert s == 201 and rv["data"]["imageUrls"] == ["http://x/y.jpg"]
            _, byrate = request(base + "/reviews/products/p-vitc?rating=5", token=cust)
            assert byrate["data"]["totalElements"] == 0 and byrate["data"]["summary"]["count"] == 1
            assert request(base + f"/reviews/{rv['data']['id']}/reply", "PUT", {"reply": "Cảm ơn bạn"}, cust)[0] == 403
            s, rep = request(base + f"/reviews/{rv['data']['id']}/reply", "PUT", {"reply": "Cảm ơn bạn"}, staff)
            assert s == 200 and rep["data"]["staffReply"] == "Cảm ơn bạn"
            _, pending = request(base + "/reviews/staff?replied=false", token=staff)
            assert pending["data"]["totalElements"] == 0
            _, prod = request(base + "/products/p-vitc")
            assert prod["data"]["ratingAverage"] == 4.0 and prod["data"]["reviewCount"] == 1
            _, top = request(base + "/products?minRating=4&size=50")
            assert {x["id"] for x in top["data"]["content"]} == {"p-vitc"}

            # ---- chat dược sĩ + trạng thái online + ghi chú tư vấn
            _, pres = request(base + "/chat/presence", token=cust)
            assert pres["data"]["pharmacistOnline"] is False
            request(base + "/chat/presence", "PUT", {"online": True}, staff)
            assert request(base + "/chat/presence", token=cust)[1]["data"]["pharmacistOnline"] is True
            _, conv = request(base + "/chat/my-conversation", token=cust)
            cid = conv["data"]["id"]
            s, m1 = request(base + f"/chat/conversations/{cid}/messages", "POST", {"content": "Em bị đau đầu, uống gì ạ?"}, cust)
            assert s == 201 and m1["data"]["senderRole"] == "CUSTOMER"
            _, sl = request(base + "/chat/conversations", token=staff)
            assert sl["data"][0]["unreadForStaff"] == 1
            assert request(base + "/chat/conversations", token=cust)[0] == 403
            s, m2 = request(base + f"/chat/conversations/{cid}/messages", "POST", {"content": "Bạn thử Paracetamol nhé", "productId": "p-paracetamol"}, staff)
            assert s == 201 and m2["data"]["senderRole"] == "PHARMACIST" and m2["data"]["productName"] == "Paracetamol 500mg"
            _, msgs = request(base + f"/chat/conversations/{cid}/messages", token=cust)
            assert len(msgs["data"]) == 2
            _, newer = request(base + f"/chat/conversations/{cid}/messages?after={quote(m1['data']['createdAt'])}", token=cust)
            assert [m["id"] for m in newer["data"]] == [m2["data"]["id"]]
            assert request(base + f"/chat/conversations/{cid}/messages", token=admin)[0] == 200
            assert request(base + f"/chat/conversations/conv-u-admin/messages", token=cust)[0] == 404
            s, notes = request(base + f"/chat/conversations/{cid}/notes", "POST", {"content": "Dị ứng penicillin"}, staff)
            assert s == 201 and len(notes["data"]) == 1
            assert request(base + f"/chat/conversations/{cid}/notes", token=cust)[0] == 403
            _, unread = request(base + "/notifications/unread-count", token=cust)
            assert unread["data"] >= 1  # thông báo "Dược sĩ đã phản hồi"

            # ---- chatbot
            _, bot = request(base + "/chat/bot", "POST", {"message": "Đơn hàng của tôi ở đâu?"}, cust)
            assert "AT" in bot["data"]["reply"]
            _, bot = request(base + "/chat/bot", "POST", {"message": "Paracetamol còn hàng không?"}, cust)
            assert bot["data"]["products"][0]["id"] == "p-paracetamol" and "còn hàng" in bot["data"]["reply"]
            _, bot = request(base + "/chat/bot", "POST", {"message": "nhà thuốc gần tôi"}, cust)
            assert "Quận 1" in bot["data"]["reply"]
            _, bot = request(base + "/chat/bot", "POST", {"message": "tôi bị ho"}, cust)
            assert any(p["id"] == "p-cough" for p in bot["data"]["products"])
            _, bot = request(base + "/chat/bot", "POST", {"message": "làm sao upload đơn thuốc"}, cust)
            assert "Đơn thuốc" in bot["data"]["reply"]

            # ---- hỗ trợ khách hàng
            _, faqs = request(base + "/support/faqs")
            assert len(faqs["data"]) >= 5
            _, info = request(base + "/support/info")
            assert info["data"]["hotline"]
            s, tk = request(base + "/support/tickets", "POST", {"subject": "Giao chậm", "content": "Đơn giao trễ 2 ngày", "category": "COMPLAINT"}, cust)
            assert s == 201 and tk["data"]["status"] == "OPEN"
            assert request(base + "/support/tickets", "POST", {"subject": "", "content": ""}, cust)[0] == 400
            _, stl = request(base + "/support/staff/tickets?status=OPEN", token=staff)
            assert len(stl["data"]) == 1
            assert request(base + "/support/staff/tickets", token=cust)[0] == 403
            s, upd = request(base + f"/support/staff/tickets/{tk['data']['id']}", "PUT", {"status": "RESOLVED", "reply": "Xin lỗi, đã xử lý"}, staff)
            assert s == 200 and upd["data"]["status"] == "RESOLVED" and len(upd["data"]["messages"]) == 2
            _, mine = request(base + f"/support/tickets/{tk['data']['id']}", token=cust)
            assert mine["data"]["statusLabel"] == "Đã giải quyết"
            assert request(base + f"/support/tickets/{tk['data']['id']}", token=admin)[0] == 200

            # ---- upload từ Flutter Web: tên file có thể không có đuôi
            png = b"\x89PNG\r\n\x1a\n" + b"0" * 32
            s, up = multipart_request(base + "/prescriptions/upload", {"patientName": "Khách"}, [("files", "blob", "image/png", png)], cust)
            assert s == 201 and up["data"]["images"][0]["imageUrl"].endswith(".png")
            s, up = multipart_request(base + "/files/upload", {}, [("file", "photo", "image/jpeg", b"\xff\xd8\xff\xe0" + b"0" * 16)], cust)
            assert s == 201 and up["data"]["fileUrl"].endswith(".jpg")
            s, _ = multipart_request(base + "/files/upload", {}, [("file", "malware", "application/octet-stream", b"MZ" + b"0" * 16)], cust)
            assert s == 400

            # ---- đơn thuốc: dược sĩ gợi ý sản phẩm + thông báo cho khách
            _, rx = request(base + "/prescriptions", "POST", {"patientName": "Khách", "imageUrls": ["http://x/rx.jpg"]}, cust)
            s, rv2 = request(base + f"/prescriptions/admin/{rx['data']['id']}/review", "PUT",
                             {"status": "APPROVED", "pharmacistNote": "Hợp lệ", "suggestedProductIds": ["p-omeprazole", "p-probiotic"]}, staff)
            assert s == 200 and [x["id"] for x in rv2["data"]["suggestedProducts"]] == ["p-omeprazole", "p-probiotic"]
            _, nts = request(base + "/notifications", token=cust)
            types = {n["type"] for n in nts["data"]}
            assert {"ORDER", "LOYALTY", "PRESCRIPTION", "CONSULTATION"} <= types, types

            print("PASS: extras — catalog/search/filter, favorites, reminders, health profile, loyalty, reorder/invoice/refund, reviews, chat/bot, support, prescription suggestions")
        finally:
            proc.terminate()
            proc.wait(timeout=5)

    # ---- scheduler: nhắc thuốc và theo dõi yêu thích (gọi trực tiếp, không cần chờ thời gian thật)
    import importlib
    sys.path.insert(0, str(ROOT))
    extras = importlib.import_module("extras")
    app = importlib.import_module("app")
    with tempfile.TemporaryDirectory(prefix="antam-sched-") as tmp:
        app.DB_PATH = Path(tmp) / "s.sqlite3"
        app.seed()
        sent_fcm = []
        fake_fcm = lambda tokens, title, content, data=None: sent_fcm.append((tokens, title))
        with app.connect() as db:
            db.execute("INSERT INTO device_tokens VALUES('d1','u-customer','tok-1','ANDROID',?)", (extras.NOW(),))
            extras.save(db, "reminders", "r1", "u-customer", {"id": "r1", "medicineName": "Vitamin C", "dosage": "1 viên",
                                                              "times": ["07:30"], "repeat": "DAILY", "isActive": True})
            extras.save(db, "reminders", "r2", "u-customer", {"id": "r2", "medicineName": "Thuốc tuần", "times": ["07:30"],
                                                              "repeat": "WEEKLY", "weekdays": [7], "isActive": True})
            extras.save(db, "favorites", "fav-u-customer-p-vitc", "u-customer",
                        {"id": "fav-u-customer-p-vitc", "productId": "p-vitc", "createdAt": extras.NOW(), "lastKnownPrice": 80000, "lastInStock": False})
        monday = datetime(2026, 11, 16, 7, 30)  # thứ Hai 07:30 giờ VN
        assert extras.reminder_tick(app.connect, fake_fcm, now=monday) == 1       # r2 chỉ nhắc Chủ nhật
        assert extras.reminder_tick(app.connect, fake_fcm, now=monday) == 0       # không gửi trùng
        sunday = datetime(2026, 11, 22, 7, 30)
        assert extras.reminder_tick(app.connect, fake_fcm, now=sunday) == 2
        assert extras.reminder_tick(app.connect, fake_fcm, now=datetime(2026, 11, 16, 7, 31)) == 0
        assert sent_fcm and sent_fcm[0][0] == ["tok-1"] and sent_fcm[0][1] == "Đã đến giờ uống thuốc"
        assert extras.favorites_tick(app.connect, fake_fcm) == 2                   # giá 65.000 < 80.000 và có hàng lại
        assert extras.favorites_tick(app.connect, fake_fcm) == 0
    print("PASS: scheduler — medication reminders (daily/weekly, dedupe) and favorite price/stock alerts")

    # ---- MoMo: gọi trực tiếp handler với MoMo giả (không cần mạng)
    momo = importlib.import_module("momo")
    with tempfile.TemporaryDirectory(prefix="antam-momo-") as tmp:
        app.DB_PATH = Path(tmp) / "m.sqlite3"
        app.seed()
        customer = {"id": "u-customer", "roles": ["CUSTOMER"], "fullName": "Khách"}
        stranger = {"id": "u-staff", "roles": ["PHARMACIST"], "fullName": "NV"}
        out = []
        send = lambda body, code=200: out.append((code, body))
        fcm = []
        send_fcm = lambda tokens, title, content, data=None: fcm.append(title)
        posted, state = [], {"query": {"resultCode": 1000, "message": "Dang cho"}, "down": False}

        def fake_post(url, payload, timeout=20):
            if state["down"]:
                raise momo.MomoError("Không kết nối được tới MoMo, vui lòng thử lại")
            posted.append((url, payload))
            if url.endswith("/create"):
                return {"resultCode": 0, "payUrl": "https://test-payment.momo.vn/pay/abc", "deeplink": "momo://app", "qrCodeUrl": "momo://qr"}
            return state["query"]
        momo.post_json = fake_post

        def call(method, path, data=None, user=customer):
            out.clear()
            with app.connect() as db:
                handled = extras.handle(send, db, send_fcm, method, path, {}, data or {}, user)
            assert handled
            return out[-1]

        def make_order(oid, amount):
            with app.connect() as db:
                extras.save(db, "orders", oid, "u-customer", {
                    "id": oid, "orderCode": "AT" + oid.upper(), "userId": "u-customer", "finalAmount": amount, "paymentMethod": "MOMO",
                    "paymentStatus": "PENDING", "orderStatus": "PENDING", "statusHistories": []})

        make_order("o1", 195000)
        code, body = call("POST", "/payments/momo/create-payment", {"orderId": "o1"})
        assert code == 201 and body["data"]["payUrl"].startswith("https://test-payment.momo.vn") and body["data"]["sandbox"] is True
        url, sent = posted[-1]
        assert url.endswith("/v2/gateway/api/create") and sent["amount"] == 195000 and sent["requestType"] == "captureWallet"
        cfg = momo.config()
        raw = (f"accessKey={cfg['accessKey']}&amount={sent['amount']}&extraData={sent['extraData']}&ipnUrl={sent['ipnUrl']}"
               f"&orderId={sent['orderId']}&orderInfo={sent['orderInfo']}&partnerCode={sent['partnerCode']}"
               f"&redirectUrl={sent['redirectUrl']}&requestId={sent['requestId']}&requestType={sent['requestType']}")
        assert sent["signature"] == momo.sign(cfg["secretKey"], raw) and len(sent["signature"]) == 64
        assert call("POST", "/payments/momo/create-payment", {"orderId": "o1"}, stranger)[0] == 404   # đơn của người khác

        code, body = call("POST", "/payments/momo/verify", {"orderId": "o1"})            # MoMo: đang chờ
        assert code == 200 and body["data"]["status"] == "PENDING" and body["data"]["resultCode"] == 1000
        state["query"] = {"resultCode": 0, "amount": 195000, "transId": 777, "message": "OK"}
        code, body = call("POST", "/payments/momo/verify", {"orderId": "o1"})            # thanh toán xong
        assert code == 200 and body["data"]["status"] == "PAID" and body["data"]["payment"]["transactionCode"] == "777"
        with app.connect() as db:
            assert extras.get(db, "orders", "o1")[1]["paymentStatus"] == "PAID"
            assert any(n["type"] == "PAYMENT" for _, _, n in extras.load(db, "notifications", "u-customer"))
        assert call("POST", "/payments/momo/create-payment", {"orderId": "o1"})[0] == 409   # đã thanh toán

        make_order("o2", 100000)                                                          # số tiền MoMo trả về không khớp
        call("POST", "/payments/momo/create-payment", {"orderId": "o2"})
        state["query"] = {"resultCode": 0, "amount": 1000, "transId": 1}
        assert call("POST", "/payments/momo/verify", {"orderId": "o2"})[0] == 409
        state["query"] = {"resultCode": 1006, "message": "Nguoi dung tu choi"}            # khách hủy trên MoMo
        code, body = call("POST", "/payments/momo/verify", {"orderId": "o2"})
        assert body["data"]["status"] == "FAILED"

        make_order("o3", 50000)                                                           # IPN
        call("POST", "/payments/momo/create-payment", {"orderId": "o3"})
        with app.connect() as db:
            momo_order = extras.payment_of_order(db, "o3")[2]["momoOrderId"]
        ipn = {"partnerCode": cfg["partnerCode"], "orderId": momo_order, "requestId": "RQ1", "amount": 50000, "orderInfo": "x",
               "orderType": "momo_wallet", "transId": 555, "resultCode": 0, "message": "OK", "payType": "qr",
               "responseTime": 1, "extraData": ""}
        bad = dict(ipn, signature="0" * 64)
        assert call("POST", "/payments/momo/ipn", bad, None)[0] == 400
        assert call("POST", "/payments/momo/ipn", dict(ipn, signature=momo.ipn_signature(cfg, ipn)), None)[0] == 200
        with app.connect() as db:
            assert extras.payment_of_order(db, "o3")[2]["paymentStatus"] == "PAID"

        make_order("o4", 500)                                                             # dưới mức tối thiểu của MoMo
        assert call("POST", "/payments/momo/create-payment", {"orderId": "o4"})[0] == 502
        make_order("o5", 90000)
        state["down"] = True                                                              # MoMo không truy cập được
        code, body = call("POST", "/payments/momo/create-payment", {"orderId": "o5"})
        assert code == 502 and "MoMo" in body["message"]
        assert call("GET", "/payments/momo/return", None, None)[1].startswith("<!doctype html>")
    print("PASS: MoMo — signing, create/verify/IPN, amount check, failure and unreachable-gateway handling")


if __name__ == "__main__":
    main()
