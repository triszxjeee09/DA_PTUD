"""Tích hợp ví MoMo (API v2 - captureWallet).

Mặc định dùng môi trường **sandbox** với bộ khóa thử nghiệm công khai trong tài liệu
MoMo (https://developers.momo.vn). Khi có tài khoản MoMo Business, đặt các biến môi trường:

    PHARMA_MOMO_PARTNER_CODE, PHARMA_MOMO_ACCESS_KEY, PHARMA_MOMO_SECRET_KEY,
    PHARMA_MOMO_ENDPOINT   (production: https://payment.momo.vn/v2/gateway/api)
    PHARMA_PUBLIC_URL      (địa chỉ công khai của backend, VD https://xxxx.ngrok-free.app)

Backend không cần địa chỉ công khai để hoạt động: sau khi khách thanh toán, ứng dụng gọi
``/payments/momo/verify`` và backend tự hỏi MoMo (API query) để biết kết quả. IPN chỉ là kênh bổ sung.
"""
from __future__ import annotations

import hashlib
import hmac
import json
import os
import time
import urllib.error
import urllib.request

# Khóa sandbox công khai trong tài liệu MoMo. Không dùng cho tiền thật.
SANDBOX_PARTNER_CODE = "MOMO"
SANDBOX_ACCESS_KEY = "F8BBA842ECF85"
SANDBOX_SECRET_KEY = "K951B6PE1waDMi640xX08PD3vg6EkVlz"
SANDBOX_ENDPOINT = "https://test-payment.momo.vn/v2/gateway/api"

MIN_AMOUNT, MAX_AMOUNT = 1000, 50_000_000  # giới hạn của MoMo (VND)
PENDING_CODES = {1000, 7000, 7002, 9000}


class MomoError(Exception):
    """Lỗi kết nối hoặc phản hồi không hợp lệ từ MoMo."""


def config() -> dict:
    """Đọc cấu hình tại thời điểm gọi để dễ đổi biến môi trường khi kiểm thử."""
    public = os.environ.get("PHARMA_PUBLIC_URL") or f"http://localhost:{os.environ.get('PORT', '8082')}"
    public = public.rstrip("/")
    return {
        "partnerCode": os.environ.get("PHARMA_MOMO_PARTNER_CODE", SANDBOX_PARTNER_CODE),
        "accessKey": os.environ.get("PHARMA_MOMO_ACCESS_KEY", SANDBOX_ACCESS_KEY),
        "secretKey": os.environ.get("PHARMA_MOMO_SECRET_KEY", SANDBOX_SECRET_KEY),
        "endpoint": os.environ.get("PHARMA_MOMO_ENDPOINT", SANDBOX_ENDPOINT).rstrip("/"),
        "redirectUrl": os.environ.get("PHARMA_MOMO_REDIRECT_URL", f"{public}/api/v1/payments/momo/return"),
        "ipnUrl": os.environ.get("PHARMA_MOMO_IPN_URL", f"{public}/api/v1/payments/momo/ipn"),
        "isSandbox": os.environ.get("PHARMA_MOMO_ENDPOINT", SANDBOX_ENDPOINT).startswith(SANDBOX_ENDPOINT),
    }


def sign(secret_key: str, raw: str) -> str:
    return hmac.new(secret_key.encode(), raw.encode(), hashlib.sha256).hexdigest()


def post_json(url: str, payload: dict, timeout: int = 20) -> dict:
    request = urllib.request.Request(
        url, data=json.dumps(payload).encode(), headers={"Content-Type": "application/json; charset=UTF-8"}, method="POST")
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return json.loads(response.read().decode() or "{}")
    except urllib.error.HTTPError as error:
        body = error.read().decode(errors="ignore")
        try:
            return json.loads(body)
        except ValueError:
            raise MomoError(f"MoMo trả về HTTP {error.code}") from error
    except (urllib.error.URLError, TimeoutError, OSError) as error:
        raise MomoError("Không kết nối được tới MoMo, vui lòng thử lại") from error
    except ValueError as error:
        raise MomoError("Phản hồi của MoMo không hợp lệ") from error


def new_ids(order_code: str) -> tuple[str, str]:
    stamp = int(time.time() * 1000)
    return f"{order_code}-{stamp}"[:50], f"RQ{stamp}"


def create_payment(order_code: str, amount: int, order_info: str) -> dict:
    """Tạo giao dịch MoMo. Trả về dict gồm payUrl, deeplink, qrCodeUrl, momoOrderId, momoRequestId."""
    if not MIN_AMOUNT <= amount <= MAX_AMOUNT:
        raise MomoError("MoMo chỉ hỗ trợ số tiền từ 1.000đ đến 50.000.000đ")
    cfg = config()
    order_id, request_id = new_ids(order_code)
    extra, request_type = "", "captureWallet"
    raw = (f"accessKey={cfg['accessKey']}&amount={amount}&extraData={extra}&ipnUrl={cfg['ipnUrl']}"
           f"&orderId={order_id}&orderInfo={order_info}&partnerCode={cfg['partnerCode']}"
           f"&redirectUrl={cfg['redirectUrl']}&requestId={request_id}&requestType={request_type}")
    body = {
        "partnerCode": cfg["partnerCode"], "partnerName": "An Tam Pharma", "storeId": "AnTamPharma",
        "requestId": request_id, "amount": amount, "orderId": order_id, "orderInfo": order_info,
        "redirectUrl": cfg["redirectUrl"], "ipnUrl": cfg["ipnUrl"], "lang": "vi", "requestType": request_type,
        "autoCapture": True, "extraData": extra, "signature": sign(cfg["secretKey"], raw),
    }
    result = post_json(f"{cfg['endpoint']}/create", body)
    if int(result.get("resultCode", -1)) != 0:
        raise MomoError(f"MoMo từ chối giao dịch: {result.get('message', 'không rõ lý do')}")
    return {"payUrl": result.get("payUrl"), "deeplink": result.get("deeplink"),
            "qrCodeUrl": result.get("qrCodeUrl"), "momoOrderId": order_id, "momoRequestId": request_id}


def query_payment(momo_order_id: str) -> dict:
    """Hỏi MoMo trạng thái giao dịch. Trả về dict của MoMo (resultCode, amount, transId, message...)."""
    cfg = config()
    request_id = f"RQ{int(time.time() * 1000)}"
    raw = (f"accessKey={cfg['accessKey']}&orderId={momo_order_id}"
           f"&partnerCode={cfg['partnerCode']}&requestId={request_id}")
    body = {"partnerCode": cfg["partnerCode"], "requestId": request_id, "orderId": momo_order_id,
            "lang": "vi", "signature": sign(cfg["secretKey"], raw)}
    return post_json(f"{cfg['endpoint']}/query", body)


def ipn_signature(cfg: dict, data: dict) -> str:
    keys = ("amount", "extraData", "message", "orderId", "orderInfo", "orderType", "partnerCode", "payType",
            "requestId", "responseTime", "resultCode", "transId")
    raw = f"accessKey={cfg['accessKey']}&" + "&".join(f"{k}={data.get(k, '')}" for k in keys)
    return sign(cfg["secretKey"], raw)


def verify_ipn(data: dict) -> bool:
    cfg = config()
    expected = ipn_signature(cfg, data)
    return hmac.compare_digest(expected, str(data.get("signature", "")))
