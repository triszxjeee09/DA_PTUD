"""Tính năng mở rộng cho An Tâm Pharma (SQLite + REST + FCM).

Module này được app.py gọi trước các route cũ. Dữ liệu dùng chung bảng ``records``
(kind, id, ownerId, payload JSON) nên không cần migration phức tạp.

Nhóm tính năng: yêu thích, nhắc uống thuốc, hồ sơ sức khỏe gia đình, chat với dược sĩ
+ chatbot, hỗ trợ khách hàng (FAQ/ticket), điểm thưởng/hạng thành viên, mua lại nhanh,
hóa đơn, hoàn tiền, thuốc thường dùng, đánh giá nâng cao và bộ lọc sản phẩm.
"""
from __future__ import annotations

import json
import os
import re
import secrets
import time
import unicodedata
from datetime import datetime, timedelta, timezone

import momo

STAFF_ROLES = {"ADMIN", "PHARMACIST"}
# App Flutter dùng DELIVERED, dữ liệu cũ dùng COMPLETED: cả hai đều là đơn đã hoàn tất.
DONE_STATUSES = ("COMPLETED", "DELIVERED")
TZ_HOURS = int(os.environ.get("PHARMA_TZ_OFFSET", "7"))  # Việt Nam UTC+7
SETTINGS_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "settings.local.json")
_BANK_DEFAULTS = {"bankId": "970422", "bankName": "MB Bank", "accountNo": "0123456789", "accountName": "NHA THUOC AN TAM"}
_BANK_ENV = {"bankId": "PHARMA_BANK_ID", "bankName": "PHARMA_BANK_NAME", "accountNo": "PHARMA_BANK_ACCOUNT",
             "accountName": "PHARMA_BANK_OWNER"}


def local_settings() -> dict:
    """Đọc backend/settings.local.json (không đưa lên git). Đọc lại mỗi lần gọi nên sửa file không cần restart."""
    try:
        with open(SETTINGS_FILE, encoding="utf-8-sig") as handle:
            data = json.load(handle)
        return data if isinstance(data, dict) else {}
    except (OSError, ValueError):
        return {}


def bank_info() -> dict:
    """Tài khoản nhận tiền: mặc định < settings.local.json < biến môi trường."""
    saved = local_settings().get("bank", {})
    info = dict(_BANK_DEFAULTS)
    for key, env_name in _BANK_ENV.items():
        if str(saved.get(key, "")).strip():
            info[key] = str(saved[key]).strip()
        if os.environ.get(env_name, "").strip():
            info[key] = os.environ[env_name].strip()
    return info


def hotline() -> str:
    return os.environ.get("PHARMA_HOTLINE") or str(local_settings().get("hotline") or "1900 1234")


def _tlv(tag: str, value: str) -> str:
    return f"{tag}{len(value):02d}{value}"


def crc16_ccitt(text: str) -> str:
    crc = 0xFFFF
    for byte in text.encode():
        crc ^= byte << 8
        for _ in range(8):
            crc = ((crc << 1) ^ 0x1021) & 0xFFFF if crc & 0x8000 else (crc << 1) & 0xFFFF
    return f"{crc:04X}"


def vietqr_payload(bank_id: str, account_no: str, amount: int, memo: str) -> str:
    """Chuỗi VietQR (chuẩn NAPAS 247, EMVCo) để app tự vẽ mã QR, không phụ thuộc dịch vụ ảnh bên ngoài."""
    receiver = _tlv("00", bank_id) + _tlv("01", account_no)
    merchant = _tlv("00", "A000000727") + _tlv("01", receiver) + _tlv("02", "QRIBFTTA")
    body = (_tlv("00", "01") + _tlv("01", "12") + _tlv("38", merchant) + _tlv("53", "704")
            + (_tlv("54", str(int(amount))) if amount else "") + _tlv("58", "VN")
            + _tlv("62", _tlv("08", memo[:25])) + "6304")
    return body + crc16_ccitt(body)


def sniff_extension(content_type, data: bytes):
    """Đoán đuôi file hợp lệ từ nội dung (chữ ký đầu file) hoặc content-type; None nếu không nhận ra."""
    head = bytes(data[:12])
    if head[:3] == b"\xff\xd8\xff":
        return ".jpg"
    if head[:4] == b"\x89PNG":
        return ".png"
    if head[:4] == b"RIFF" and head[8:12] == b"WEBP":
        return ".webp"
    if head[:4] == b"%PDF":
        return ".pdf"
    return None


def NOW() -> str:
    return datetime.now(timezone.utc).isoformat()


def api(data=None, message="Thành công", status=200):
    return {"status": status, "message": message, "data": data}


def fold(text) -> str:
    """Chuẩn hóa không dấu, chữ thường để tìm kiếm tiếng Việt."""
    text = unicodedata.normalize("NFD", str(text or "").lower().replace("đ", "d"))
    return "".join(c for c in text if unicodedata.category(c) != "Mn")


def page_of(items, q):
    page = int(q.get("page", 0) or 0)
    size = max(1, int(q.get("size", 10) or 10))
    total = len(items)
    content = items[page * size:(page + 1) * size]
    return {
        "content": content, "page": page, "size": size, "totalElements": total,
        "totalPages": max(1, (total + size - 1) // size), "last": (page + 1) * size >= total,
        "first": page == 0, "numberOfElements": len(content), "empty": not content,
    }


# ----------------------------------------------------------------------------- lưu trữ
def load(db, kind, owner=None):
    sql, params = "SELECT id, ownerId, payload FROM records WHERE kind=?", [kind]
    if owner is not None:
        sql += " AND ownerId=?"
        params.append(owner)
    sql += " ORDER BY createdAt"
    return [(r["id"], r["ownerId"], json.loads(r["payload"])) for r in db.execute(sql, params)]


def get(db, kind, rid):
    row = db.execute("SELECT ownerId, payload FROM records WHERE kind=? AND id=?", (kind, rid)).fetchone()
    return (row["ownerId"], json.loads(row["payload"])) if row else (None, None)


def save(db, kind, rid, owner, payload):
    text = json.dumps(payload, ensure_ascii=False)
    if db.execute("SELECT 1 FROM records WHERE kind=? AND id=?", (kind, rid)).fetchone():
        db.execute("UPDATE records SET payload=? WHERE kind=? AND id=?", (text, kind, rid))
    else:
        db.execute("INSERT INTO records VALUES(?,?,?,?,?)", (kind, rid, owner, text, NOW()))


def remove(db, kind, rid, owner=None):
    if owner is None:
        db.execute("DELETE FROM records WHERE kind=? AND id=?", (kind, rid))
    else:
        db.execute("DELETE FROM records WHERE kind=? AND id=? AND ownerId=?", (kind, rid, owner))


def notify(db, send_fcm, user_id, title, content, ntype="GENERAL", reference_id=None):
    """Lưu thông báo trong ứng dụng và gửi FCM nếu đã cấu hình Firebase Admin."""
    nid = "nt-" + secrets.token_hex(6)
    payload = {"id": nid, "title": title, "content": content, "type": ntype,
               "referenceId": reference_id, "isRead": False, "createdAt": NOW()}
    save(db, "notifications", nid, user_id, payload)
    tokens = [r["token"] for r in db.execute("SELECT token FROM device_tokens WHERE userId=?", (user_id,))]
    if tokens and send_fcm:
        try:
            send_fcm(tokens, title, content, {"type": ntype, "referenceId": reference_id})
        except Exception as error:  # push lỗi không được làm hỏng API chính
            print(f"FCM notify failed: {error}", flush=True)


def cart_payload(db, uid):
    """Giỏ hàng đầy đủ của người dùng (cùng định dạng với GET /cart)."""
    entries = [p for _, _, p in load(db, "cart", uid)]
    return {"id": "cart-" + uid, "status": "ACTIVE", "items": entries,
            "totalItems": sum(int(x.get("quantity", 1) or 1) for x in entries),
            "totalAmount": sum(float(x.get("unitPrice", x.get("price", 0)) or 0) * int(x.get("quantity", 1) or 1) for x in entries),
            "hasPrescriptionProduct": any(x.get("requiresPrescription", False) for x in entries)}


def product_stock(db, product_id) -> int:
    row = db.execute(
        "SELECT COALESCE(SUM(json_extract(payload,'$.quantity')),0) AS n FROM records "
        "WHERE kind='inventory' AND json_extract(payload,'$.productId')=?", (product_id,)).fetchone()
    return int(row["n"] or 0)


def product_dict(db, row):
    item = dict(row)
    item["images"] = json.loads(item.get("images") or "[]")
    for key in ("isActive", "isFeatured", "requiresPrescription"):
        item[key] = bool(item.get(key))
    return item


# ----------------------------------------------------------------------------- sản phẩm
EXTRA_PRODUCT_COLUMNS = ("dosageForm", "targetAudience", "symptoms", "manufacturer", "contraindications")


def migrate(db):
    """Thêm cột/dữ liệu mẫu còn thiếu. An toàn khi chạy nhiều lần."""
    columns = {r["name"] for r in db.execute("PRAGMA table_info(products)")}
    for name in EXTRA_PRODUCT_COLUMNS:
        if name not in columns:
            db.execute(f"ALTER TABLE products ADD COLUMN {name} TEXT")
    seed_catalog(db)


DETAILS = {
    "p-paracetamol": dict(
        dosageForm="Viên nén", targetAudience="Người lớn; trẻ em dùng theo cân nặng và tư vấn dược sĩ",
        symptoms="đau đầu, sốt, đau răng, đau cơ, đau họng", manufacturer="DHG Pharma",
        ingredients="Paracetamol 500mg", shortDescription="Giảm đau nhẹ đến vừa và hạ sốt",
        usageInstructions="Uống với nước, sau ăn nhẹ nếu cần. Khoảng cách giữa các liều tối thiểu 4–6 giờ.",
        dosage="Người lớn: 1 viên/lần, tối đa 6 viên/24 giờ (liều tham khảo). Trẻ em: theo cân nặng, hỏi dược sĩ.",
        sideEffects="Hiếm: phát ban, buồn nôn. Quá liều có thể gây tổn thương gan.",
        precautions="Không dùng chung thuốc khác chứa paracetamol. Thận trọng khi có bệnh gan, nghiện rượu.",
        contraindications="Mẫn cảm với paracetamol; suy gan nặng.",
        storageInstructions="Nơi khô ráo, dưới 30°C, tránh ánh sáng."),
    "p-vitc": dict(
        dosageForm="Viên sủi", targetAudience="Người lớn và trẻ em trên 12 tuổi",
        symptoms="mệt mỏi, cảm cúm, đề kháng kém", manufacturer="Sanofi",
        ingredients="Vitamin C (acid ascorbic) 1000mg", shortDescription="Bổ sung vitamin C, hỗ trợ tăng đề kháng",
        usageInstructions="Hòa 1 viên sủi trong 200ml nước, uống sau khi tan hết.",
        dosage="1 viên/ngày (liều tham khảo).", sideEffects="Có thể gây khó chịu dạ dày nếu dùng liều cao.",
        precautions="Người có sỏi thận cần hỏi ý kiến bác sĩ trước khi dùng.",
        contraindications="Mẫn cảm với thành phần của sản phẩm.",
        storageInstructions="Đậy kín nắp, nơi khô ráo."),
    "p-omeprazole": dict(
        dosageForm="Viên nang", targetAudience="Người lớn theo chỉ định của bác sĩ",
        symptoms="trào ngược dạ dày, ợ nóng, đau thượng vị, loét dạ dày", manufacturer="Pfizer",
        ingredients="Omeprazole 20mg", shortDescription="Giảm tiết acid dạ dày (thuốc kê đơn)",
        usageInstructions="Uống trước bữa ăn sáng 30 phút, nuốt nguyên viên.",
        dosage="Theo đơn của bác sĩ.", sideEffects="Đau đầu, tiêu chảy, buồn nôn.",
        precautions="Chỉ dùng khi có đơn thuốc đã được dược sĩ duyệt.",
        contraindications="Mẫn cảm với omeprazole hoặc nhóm ức chế bơm proton.",
        storageInstructions="Dưới 25°C, tránh ẩm."),
    "p-saline": dict(
        dosageForm="Dung dịch", targetAudience="Mọi lứa tuổi", symptoms="nghẹt mũi, sổ mũi, vệ sinh mắt",
        manufacturer="DHG Pharma", ingredients="Natri clorid 0,9%", shortDescription="Vệ sinh mắt, mũi, họng",
        usageInstructions="Nhỏ hoặc rửa vùng cần vệ sinh theo hướng dẫn trên bao bì.",
        dosage="Dùng 2–3 lần/ngày hoặc khi cần.", sideEffects="Hiếm khi gặp.",
        precautions="Không dùng khi chai đã mở quá lâu hoặc có dấu hiệu đục.",
        contraindications="Không có chống chỉ định đặc biệt.", storageInstructions="Nơi sạch, khô ráo."),
    "p-calcium": dict(
        dosageForm="Viên nén", targetAudience="Người lớn, người cao tuổi; phụ nữ mang thai hỏi ý kiến bác sĩ",
        symptoms="loãng xương, thiếu canxi, đau mỏi xương", manufacturer="Sanofi",
        ingredients="Calcium carbonate, Vitamin D3", shortDescription="Bổ sung canxi và vitamin D3",
        usageInstructions="Uống trong hoặc sau bữa ăn.", dosage="1–2 viên/ngày (liều tham khảo).",
        sideEffects="Táo bón, đầy hơi.", precautions="Thận trọng khi có sỏi thận hoặc tăng canxi máu.",
        contraindications="Tăng canxi máu, sỏi thận nặng.", storageInstructions="Nơi khô ráo, dưới 30°C."),
    "p-cough": dict(
        dosageForm="Siro", targetAudience="Người lớn và trẻ em từ 2 tuổi",
        symptoms="ho, ho khan, đau rát họng, ho có đờm", manufacturer="DHG Pharma",
        ingredients="Chiết xuất thảo dược (húng chanh, cam thảo, bạc hà)", shortDescription="Siro ho thảo dược, dịu họng",
        usageInstructions="Lắc đều trước khi dùng, dùng cốc đong kèm theo.",
        dosage="Người lớn 10ml/lần, trẻ em 5ml/lần, ngày 2–3 lần (liều tham khảo).",
        sideEffects="Có thể gây buồn ngủ nhẹ.", precautions="Ngưng dùng và đi khám nếu ho kéo dài trên 7 ngày.",
        contraindications="Mẫn cảm với thành phần thảo dược.", storageInstructions="Nơi mát, đậy kín sau khi mở."),
    "p-probiotic": dict(
        dosageForm="Bột pha / viên nang", targetAudience="Người lớn và trẻ em",
        symptoms="tiêu chảy, rối loạn tiêu hóa, đầy bụng", manufacturer="Pfizer",
        ingredients="Lactobacillus acidophilus, Bifidobacterium", shortDescription="Men vi sinh hỗ trợ tiêu hóa",
        usageInstructions="Pha với nước nguội hoặc sữa ấm (không quá 40°C).",
        dosage="1–2 gói/ngày (liều tham khảo).", sideEffects="Đầy hơi nhẹ khi mới dùng.",
        precautions="Người suy giảm miễn dịch hỏi ý kiến bác sĩ.", contraindications="Mẫn cảm với thành phần.",
        storageInstructions="Bảo quản nơi mát, tránh ẩm."),
    "p-sunscreen": dict(
        dosageForm="Kem", targetAudience="Người lớn", symptoms="cháy nắng, bảo vệ da, dược mỹ phẩm",
        manufacturer="Sanofi", ingredients="Chất lọc tia UVA/UVB, chiết xuất lô hội",
        shortDescription="Kem chống nắng SPF 50+, dùng hằng ngày",
        usageInstructions="Thoa đều trước khi ra nắng 15–20 phút, thoa lại sau 2–3 giờ.",
        dosage="Lượng đủ phủ đều mặt và cổ.", sideEffects="Có thể kích ứng ở da nhạy cảm.",
        precautions="Tránh tiếp xúc mắt. Thử trên vùng da nhỏ trước khi dùng.",
        contraindications="Dị ứng thành phần.", storageInstructions="Dưới 30°C, tránh ánh nắng trực tiếp."),
}

NEW_CATEGORIES = [("cat-devices", "Thiết bị y tế"), ("cat-mom-baby", "Mẹ và bé")]
NEW_BRANDS = [("brand-omron", "Omron"), ("brand-nutri", "NutriCare")]
NEW_PRODUCTS = [
    # id, categoryId, categoryName, brandId, brandName, name, price, unit, rx, featured, extra
    ("p-thermometer", "cat-devices", "Thiết bị y tế", "brand-omron", "Omron", "Nhiệt kế điện tử", 95000, "cái", 0, 1,
     dict(dosageForm="Thiết bị", targetAudience="Mọi lứa tuổi", symptoms="sốt, đo thân nhiệt",
          manufacturer="Omron", ingredients="Không áp dụng", shortDescription="Đo thân nhiệt nhanh dưới 10 giây",
          usageInstructions="Đặt đầu đo dưới nách, chờ tiếng bíp rồi đọc kết quả.",
          dosage="Không áp dụng", sideEffects="Không có", precautions="Lau sạch đầu đo sau mỗi lần dùng.",
          contraindications="Không dùng đường miệng cho trẻ nhỏ.", storageInstructions="Tránh nơi ẩm, nhiệt cao.")),
    ("p-bp-monitor", "cat-devices", "Thiết bị y tế", "brand-omron", "Omron", "Máy đo huyết áp bắp tay", 1250000, "cái", 0, 1,
     dict(dosageForm="Thiết bị", targetAudience="Người lớn", symptoms="huyết áp cao, huyết áp thấp, chóng mặt",
          manufacturer="Omron", ingredients="Không áp dụng", shortDescription="Đo huyết áp và nhịp tim tại nhà",
          usageInstructions="Ngồi nghỉ 5 phút, đặt vòng bít ngang tim, không nói chuyện khi đo.",
          dosage="Không áp dụng", sideEffects="Không có",
          precautions="Kết quả chỉ mang tính tham khảo, không thay thế chẩn đoán của bác sĩ.",
          contraindications="Không đo trên tay có vết thương hoặc đang truyền dịch.",
          storageInstructions="Tháo pin nếu không dùng lâu ngày.")),
    ("p-mask", "cat-devices", "Thiết bị y tế", "brand-dhg", "DHG Pharma", "Khẩu trang y tế 4 lớp (hộp 50 cái)", 45000, "hộp", 0, 0,
     dict(dosageForm="Vật tư y tế", targetAudience="Mọi lứa tuổi", symptoms="phòng bụi, phòng lây bệnh hô hấp",
          manufacturer="DHG Pharma", ingredients="Vải không dệt, lớp lọc kháng khuẩn",
          shortDescription="Khẩu trang 4 lớp lọc bụi và vi khuẩn", usageInstructions="Đeo kín mũi và miệng, thay khi ẩm.",
          dosage="Không áp dụng", sideEffects="Không có", precautions="Không tái sử dụng.",
          contraindications="Không có", storageInstructions="Nơi khô ráo, sạch sẽ.")),
    ("p-vitd-baby", "cat-mom-baby", "Mẹ và bé", "brand-nutri", "NutriCare", "Vitamin D3 dạng giọt cho bé", 120000, "lọ", 0, 1,
     dict(dosageForm="Dung dịch nhỏ giọt", targetAudience="Trẻ sơ sinh và trẻ nhỏ",
          symptoms="còi xương, chậm mọc răng, thiếu vitamin D", manufacturer="NutriCare",
          ingredients="Vitamin D3 (cholecalciferol) 400 IU/giọt", shortDescription="Bổ sung vitamin D3 cho bé",
          usageInstructions="Nhỏ trực tiếp vào miệng hoặc pha với sữa.",
          dosage="1 giọt/ngày hoặc theo tư vấn của bác sĩ nhi.", sideEffects="Dùng quá liều có thể gây tăng canxi máu.",
          precautions="Hỏi ý kiến bác sĩ nhi trước khi dùng cho trẻ.", contraindications="Tăng canxi máu.",
          storageInstructions="Nơi mát, tránh ánh sáng.")),
    ("p-fever-patch", "cat-mom-baby", "Mẹ và bé", "brand-nutri", "NutriCare", "Miếng dán hạ sốt cho bé (hộp 5 miếng)", 35000, "hộp", 0, 0,
     dict(dosageForm="Miếng dán", targetAudience="Trẻ em từ 2 tuổi",
          symptoms="sốt nhẹ, nóng người", manufacturer="NutriCare", ingredients="Gel làm mát hydrogel",
          shortDescription="Hỗ trợ làm mát khi bé sốt nhẹ", usageInstructions="Dán lên trán hoặc nách, thay sau 8 giờ.",
          dosage="Không áp dụng", sideEffects="Có thể kích ứng da nhạy cảm.",
          precautions="Bé sốt cao hoặc kéo dài cần đi khám.", contraindications="Da đang tổn thương.",
          storageInstructions="Nơi khô ráo.")),
    ("p-omega3", "cat-vitamins", "Vitamin và khoáng chất", "brand-nutri", "NutriCare", "Omega-3 1000mg (lọ 60 viên)", 210000, "lọ", 0, 1,
     dict(dosageForm="Viên nang mềm", targetAudience="Người lớn", symptoms="tim mạch, mỡ máu, mắt",
          manufacturer="NutriCare", ingredients="Dầu cá (EPA, DHA) 1000mg", shortDescription="Hỗ trợ tim mạch và thị lực",
          usageInstructions="Uống sau bữa ăn.", dosage="1–2 viên/ngày (liều tham khảo).",
          sideEffects="Ợ hơi vị tanh, buồn nôn nhẹ.", precautions="Người dùng thuốc chống đông cần hỏi bác sĩ.",
          contraindications="Dị ứng hải sản/cá.", storageInstructions="Nơi mát, dưới 30°C.")),
]


def seed_catalog(db):
    for cid, name in NEW_CATEGORIES:
        if not db.execute("SELECT 1 FROM categories WHERE id=?", (cid,)).fetchone():
            db.execute("INSERT INTO categories(id,name,slug,description) VALUES(?,?,?,?)",
                       (cid, name, cid, "Sản phẩm chăm sóc sức khỏe chính hãng"))
    for bid, name in NEW_BRANDS:
        if not db.execute("SELECT 1 FROM brands WHERE id=?", (bid,)).fetchone():
            db.execute("INSERT INTO brands(id,name,slug,description) VALUES(?,?,?,?)",
                       (bid, name, bid, "Thương hiệu y tế"))
    for pid, extra in DETAILS.items():
        row = db.execute("SELECT dosageForm FROM products WHERE id=?", (pid,)).fetchone()
        if row and not row["dosageForm"]:  # chỉ điền khi chưa có, không ghi đè dữ liệu admin đã sửa
            sets = ", ".join(f"{k}=?" for k in extra)
            db.execute(f"UPDATE products SET {sets} WHERE id=?", (*extra.values(), pid))
    for pid, cid, cname, bid, bname, name, price, unit, rx, featured, extra in NEW_PRODUCTS:
        if db.execute("SELECT 1 FROM products WHERE id=?", (pid,)).fetchone():
            continue
        db.execute(
            """INSERT INTO products(id,categoryId,categoryName,brandId,brandName,name,slug,sku,shortDescription,
               description,unit,price,originalPrice,requiresPrescription,isActive,isFeatured,createdAt,updatedAt)
               VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
            (pid, cid, cname, bid, bname, name, pid, pid.upper(), extra["shortDescription"],
             "Thông tin chỉ mang tính tham khảo, không thay thế tư vấn của bác sĩ/dược sĩ.",
             unit, price, price * 1.1, rx, 1, featured, NOW(), NOW()))
        sets = ", ".join(f"{k}=?" for k in extra if k != "shortDescription")
        values = [v for k, v in extra.items() if k != "shortDescription"]
        db.execute(f"UPDATE products SET {sets} WHERE id=?", (*values, pid))
    # tồn kho cho sản phẩm mới ở mọi nhà thuốc
    shops = [json.loads(r["payload"]) for r in db.execute("SELECT payload FROM records WHERE kind='pharmacies'")]
    for shop in shops:
        for product in db.execute("SELECT id,name,sku,thumbnailUrl FROM products"):
            inv_id = f"inv-{shop['id']}-{product['id']}"
            if db.execute("SELECT 1 FROM records WHERE kind='inventory' AND id=?", (inv_id,)).fetchone():
                continue
            stock = {"id": inv_id, "pharmacyId": shop["id"], "pharmacyName": shop["name"],
                     "pharmacyAddress": shop.get("fullAddress"), "productId": product["id"],
                     "productName": product["name"], "productSku": product["sku"],
                     "productImage": product["thumbnailUrl"], "quantity": 20, "updatedAt": NOW()}
            save(db, "inventory", inv_id, None, stock)


def rating_stats(db):
    stats = {}
    for _, _, review in load(db, "reviews"):
        if not review.get("isVisible", True):
            continue
        entry = stats.setdefault(review.get("productId"), [0, 0])
        entry[0] += int(review.get("rating", 0))
        entry[1] += 1
    return {pid: (round(total / count, 1), count) for pid, (total, count) in stats.items() if count}


def decorate(db, products, user=None):
    """Thêm ratingAverage, reviewCount, inStock, isFavorite vào danh sách sản phẩm."""
    ratings = rating_stats(db)
    favorites = set()
    if user:
        favorites = {p.get("productId") for _, _, p in load(db, "favorites", user["id"])}
    for item in products:
        average, count = ratings.get(item["id"], (0, 0))
        item["ratingAverage"], item["reviewCount"] = average, count
        item["stockQuantity"] = product_stock(db, item["id"])
        item["inStock"] = item["stockQuantity"] > 0
        item["isFavorite"] = item["id"] in favorites
    return products


def filter_products(db, rows, q):
    """Tìm kiếm tên/triệu chứng/hoạt chất/nhà sản xuất + lọc nâng cao + sắp xếp."""
    keyword = fold(q.get("keyword", "")).strip()
    if keyword:
        words = keyword.split()

        def haystack(x):
            return fold(" ".join(str(x.get(k) or "") for k in (
                "name", "shortDescription", "ingredients", "symptoms", "brandName", "categoryName", "manufacturer", "sku")))
        rows = [x for x in rows if all(w in haystack(x) for w in words)]
    for field in ("categoryId", "brandId"):
        if q.get(field):
            rows = [x for x in rows if str(x.get(field)) == q[field]]
    if q.get("dosageForm"):
        rows = [x for x in rows if fold(q["dosageForm"]) in fold(x.get("dosageForm"))]
    if q.get("targetAudience"):
        rows = [x for x in rows if fold(q["targetAudience"]) in fold(x.get("targetAudience"))]
    if q.get("manufacturer"):
        rows = [x for x in rows if fold(q["manufacturer"]) in fold(x.get("manufacturer") or x.get("brandName"))]
    if q.get("minPrice"):
        rows = [x for x in rows if x["price"] >= float(q["minPrice"])]
    if q.get("maxPrice"):
        rows = [x for x in rows if x["price"] <= float(q["maxPrice"])]
    for flag in ("requiresPrescription", "isFeatured"):
        if q.get(flag):
            rows = [x for x in rows if x[flag] == (q[flag].lower() == "true")]
    if q.get("minRating") or q.get("inStock", "").lower() == "true" or q.get("sort") == "rating":
        decorate(db, rows)
        if q.get("minRating"):
            rows = [x for x in rows if x["ratingAverage"] >= float(q["minRating"])]
        if q.get("inStock", "").lower() == "true":
            rows = [x for x in rows if x["inStock"]]
    sort = q.get("sort", "")
    if sort == "price_asc":
        rows.sort(key=lambda x: x["price"])
    elif sort == "price_desc":
        rows.sort(key=lambda x: -x["price"])
    elif sort == "newest":
        rows.sort(key=lambda x: x.get("createdAt") or "", reverse=True)
    elif sort == "rating":
        rows.sort(key=lambda x: -x.get("ratingAverage", 0))
    return rows


# ----------------------------------------------------------------------------- điểm thưởng
TIERS = [("BRONZE", "Đồng", 0), ("SILVER", "Bạc", 500), ("GOLD", "Vàng", 2000), ("DIAMOND", "Kim cương", 5000)]
REWARDS = [
    {"id": "reward-10k", "name": "Voucher giảm 10.000đ", "points": 100, "discountValue": 10000, "minOrderAmount": 50000},
    {"id": "reward-30k", "name": "Voucher giảm 30.000đ", "points": 300, "discountValue": 30000, "minOrderAmount": 150000},
    {"id": "reward-50k", "name": "Voucher giảm 50.000đ", "points": 500, "discountValue": 50000, "minOrderAmount": 250000},
]
POINT_UNIT_VND = 1000  # 1 điểm cho mỗi 1.000đ thanh toán


def loyalty_summary(db, uid):
    ledger = [p for _, _, p in load(db, "loyalty_ledger", uid)]
    points = sum(int(x.get("delta", 0)) for x in ledger)
    lifetime = sum(int(x["delta"]) for x in ledger if int(x.get("delta", 0)) > 0)
    tier = TIERS[0]
    for item in TIERS:
        if lifetime >= item[2]:
            tier = item
    next_tier = next((t for t in TIERS if t[2] > lifetime), None)
    return {
        "points": points, "lifetimePoints": lifetime, "tier": tier[0], "tierLabel": tier[1],
        "nextTier": next_tier[0] if next_tier else None, "nextTierLabel": next_tier[1] if next_tier else None,
        "pointsToNextTier": (next_tier[2] - lifetime) if next_tier else 0,
        "rewards": REWARDS, "history": sorted(ledger, key=lambda x: x["createdAt"], reverse=True)[:50],
    }


def add_points(db, uid, delta, reason, kind="ADJUST", order_id=None):
    balance = sum(int(p.get("delta", 0)) for _, _, p in load(db, "loyalty_ledger", uid))
    entry = {"id": "lp-" + secrets.token_hex(6), "userId": uid, "delta": int(delta), "type": kind,
             "reason": reason, "orderId": order_id, "balanceAfter": balance + int(delta), "createdAt": NOW()}
    save(db, "loyalty_ledger", entry["id"], uid, entry)
    return entry


def award_order_points(db, send_fcm, order):
    """Cộng điểm đúng một lần khi đơn hoàn tất."""
    if order.get("pointsAwarded"):
        return order
    points = int(float(order.get("finalAmount", 0)) // POINT_UNIT_VND)
    order["pointsAwarded"] = True
    order["pointsEarned"] = points
    if points > 0:
        add_points(db, order["userId"], points, f"Hoàn tất đơn {order.get('orderCode')}", "EARN", order["id"])
        notify(db, send_fcm, order["userId"], "Bạn được cộng điểm thưởng",
               f"Đơn {order.get('orderCode')} hoàn tất, bạn nhận {points} điểm.", "LOYALTY", order["id"])
    return order


# ----------------------------------------------------------------------------- chatbot
def bot_reply(db, user, text):
    t = fold(text)
    generic = {"vitamin", "kem", "siro", "nuoc", "muoi", "sinh", "khau", "trang", "may", "dang", "giot", "mieng",
               "dan", "hop", "vien", "thao", "duoc", "cho", "men", "khong", "dien", "tu", "lop", "cai", "chai"}
    scored_names = []
    for row in db.execute("SELECT * FROM products WHERE isActive=1"):
        tokens = [w for w in re.findall(r"[a-z0-9]+", fold(row["name"])) if len(w) >= 3 and w not in generic]
        hits = sum(1 for w in tokens if re.search(rf"\b{re.escape(w)}\b", t))
        if hits:
            scored_names.append((hits, product_dict(db, row)))
    scored_names.sort(key=lambda x: -x[0])
    products = [p for h, p in scored_names if h == scored_names[0][0]][:3] if scored_names else []
    suggestions = ["Đơn hàng của tôi ở đâu?", "Nhà thuốc gần tôi", "Hướng dẫn upload đơn thuốc", "Gặp dược sĩ"]

    if any(k in t for k in ("don hang", "van chuyen", "giao hang", "trang thai don")):
        orders = [p for _, _, p in load(db, "orders", user["id"])] if user else []
        orders.sort(key=lambda x: x["createdAt"], reverse=True)
        if not user:
            return {"reply": "Bạn hãy đăng nhập để mình tra cứu đơn hàng nhé.", "suggestions": suggestions, "products": []}
        if not orders:
            return {"reply": "Bạn chưa có đơn hàng nào. Hãy chọn sản phẩm và đặt hàng thử nhé!", "suggestions": suggestions, "products": []}
        lines = [f"• {o['orderCode']}: {o.get('orderStatusLabel', o['orderStatus'])}" for o in orders[:3]]
        return {"reply": "Các đơn gần nhất của bạn:\n" + "\n".join(lines), "suggestions": suggestions, "products": []}
    if products and any(k in t for k in ("con hang", "ton kho", "het hang", "co san")):
        p = products[0]
        stock = product_stock(db, p["id"])
        shops = []
        for _, _, inv in load(db, "inventory"):
            if inv.get("productId") == p["id"] and int(inv.get("quantity", 0)) > 0:
                shops.append(f"• {inv.get('pharmacyName')}: {inv['quantity']} {p.get('unit') or ''}")
        text_out = (f"{p['name']} hiện còn hàng ({stock} {p.get('unit') or ''}):\n" + "\n".join(shops)) if stock else \
            f"{p['name']} hiện đã hết hàng. Bạn có thể bấm yêu thích để nhận thông báo khi có hàng lại."
        return {"reply": text_out, "suggestions": suggestions, "products": [p]}
    if any(k in t for k in ("nha thuoc", "chi nhanh", "gan toi", "dia chi")):
        shops = [p for _, _, p in load(db, "pharmacies") if p.get("isActive", True)]
        lines = [f"• {s['name']} — {s.get('fullAddress')} ({s.get('openingHours')})" for s in shops]
        return {"reply": "Các nhà thuốc An Tâm:\n" + "\n".join(lines) + "\nVào mục Nhà thuốc để xem khoảng cách và chỉ đường.",
                "suggestions": suggestions, "products": []}
    if any(k in t for k in ("upload", "don thuoc", "tai don", "gui don")):
        return {"reply": "Cách gửi đơn thuốc: Tài khoản → Đơn thuốc của tôi → Tải đơn mới, chụp hoặc chọn ảnh đơn thuốc rồi gửi. "
                         "Dược sĩ sẽ kiểm tra; thuốc kê đơn chỉ được đặt sau khi đơn được duyệt.",
                "suggestions": suggestions, "products": []}
    if any(k in t for k in ("diem", "hang thanh vien", "tich diem")):
        if user:
            s = loyalty_summary(db, user["id"])
            return {"reply": f"Bạn đang có {s['points']} điểm, hạng {s['tierLabel']}. Cứ 1.000đ được 1 điểm; 100 điểm đổi voucher 10.000đ.",
                    "suggestions": suggestions, "products": []}
    if any(k in t for k in ("hotline", "tong dai", "lien he", "goi")):
        return {"reply": f"Hotline hỗ trợ: {hotline()}. Bạn cũng có thể gửi yêu cầu hỗ trợ trong mục Trung tâm trợ giúp.",
                "suggestions": suggestions, "products": []}
    if any(k in t for k in ("gap duoc si", "duoc si", "tu van")):
        return {"reply": "Bạn chuyển sang tab \"Dược sĩ\" để nhắn trực tiếp với dược sĩ nhé.", "suggestions": suggestions, "products": []}
    # triệu chứng → gợi ý sản phẩm
    stop = {"toi", "bi", "la", "va", "co", "khong", "cua", "em", "anh", "chi", "bao", "nhieu", "the", "nao", "gi", "nen",
            "uong", "thuoc", "gi", "duoc", "can", "muon", "hoi", "ve", "cho", "minh", "mua"}
    tokens = {w for w in re.findall(r"[a-z0-9]+", t) if len(w) >= 2 and w not in stop}
    scored = []
    for row in db.execute("SELECT * FROM products WHERE isActive=1"):
        score = 0
        for phrase in (fold(x).strip() for x in re.split(r"[,;]", row["symptoms"] or "")):
            if phrase and phrase in t:
                score += 3
            else:
                score += len({w for w in phrase.split() if len(w) >= 2 and w not in stop} & tokens)
        hay = set(re.findall(r"[a-z0-9]+", fold(f"{row['name']} {row['ingredients'] or ''} {row['shortDescription'] or ''}")))
        score += len({w for w in tokens if len(w) > 3} & hay)
        if score:
            scored.append((score, product_dict(db, row)))
    scored.sort(key=lambda x: -x[0])
    if products or scored:
        picks = products or [p for _, p in scored[:3]]
        return {"reply": "Mình tìm thấy một số sản phẩm có thể phù hợp (chỉ mang tính tham khảo, vui lòng hỏi dược sĩ trước khi dùng):",
                "suggestions": suggestions, "products": picks}
    return {"reply": "Mình chưa hiểu rõ câu hỏi. Bạn có thể hỏi về đơn hàng, tồn kho, nhà thuốc, cách gửi đơn thuốc hoặc chọn \"Gặp dược sĩ\".",
            "suggestions": suggestions, "products": []}


FAQS = [
    {"id": "faq-1", "question": "Làm sao để mua thuốc kê đơn?", "answer": "Tải ảnh đơn thuốc trong mục Đơn thuốc. Sau khi dược sĩ duyệt, bạn chọn đơn đã duyệt khi thanh toán."},
    {"id": "faq-2", "question": "Tôi theo dõi đơn hàng ở đâu?", "answer": "Vào tab Đơn hàng, chọn đơn cần xem để thấy trạng thái và lịch sử xử lý."},
    {"id": "faq-3", "question": "Các hình thức thanh toán được hỗ trợ?", "answer": "Hiện hỗ trợ COD và chuyển khoản QR. VNPay sẽ khả dụng khi cấu hình merchant."},
    {"id": "faq-4", "question": "Tôi có thể hủy đơn không?", "answer": "Bạn hủy được khi đơn ở trạng thái Chờ xác nhận hoặc Đã xác nhận và chưa thanh toán."},
    {"id": "faq-5", "question": "Điểm thưởng được tính thế nào?", "answer": "Mỗi 1.000đ của đơn hoàn tất được 1 điểm. 100 điểm đổi voucher 10.000đ."},
    {"id": "faq-6", "question": "Thông tin thuốc trong ứng dụng có thay thế bác sĩ không?", "answer": "Không. Nội dung chỉ mang tính tham khảo, hãy hỏi dược sĩ hoặc bác sĩ trước khi dùng thuốc."},
    {"id": "faq-7", "question": "Làm sao đặt lịch nhắc uống thuốc?", "answer": "Vào Tài khoản → Nhắc uống thuốc, thêm thuốc, chọn giờ và kiểu lặp lại."},
    {"id": "faq-8", "question": "Tôi quên mật khẩu thì làm sao?", "answer": "Chọn Quên mật khẩu ở màn hình đăng nhập và làm theo hướng dẫn OTP."},
]


# ----------------------------------------------------------------------------- scheduler
def reminder_tick(connect, send_fcm, now=None):
    """Gửi thông báo nhắc uống thuốc đúng giờ (giờ Việt Nam). Trả về số thông báo đã tạo."""
    now = now or (datetime.now(timezone.utc) + timedelta(hours=TZ_HOURS))
    hhmm, today, weekday = now.strftime("%H:%M"), now.date().isoformat(), now.isoweekday()
    sent = 0
    with connect() as db:
        for rid, owner, reminder in load(db, "reminders"):
            if not reminder.get("isActive", True) or hhmm not in reminder.get("times", []):
                continue
            start, end = (reminder.get("startDate") or "")[:10], (reminder.get("endDate") or "")[:10]
            if (start and today < start) or (end and today > end):
                continue
            if reminder.get("repeat") == "WEEKLY" and weekday not in reminder.get("weekdays", []):
                continue
            key = f"{rid}:{today}:{hhmm}"
            if db.execute("SELECT 1 FROM records WHERE kind='reminder_sent' AND id=?", (key,)).fetchone():
                continue
            save(db, "reminder_sent", key, owner, {"id": key})
            who = f" ({reminder['memberName']})" if reminder.get("memberName") else ""
            notify(db, send_fcm, owner, "Đã đến giờ uống thuốc",
                   f"{reminder.get('medicineName')} — {reminder.get('dosage') or 'theo chỉ dẫn'}{who}",
                   "MEDICATION_REMINDER", rid)
            sent += 1
    return sent


def favorites_tick(connect, send_fcm):
    """Thông báo khi sản phẩm yêu thích giảm giá hoặc có hàng lại."""
    sent = 0
    with connect() as db:
        for fid, owner, fav in load(db, "favorites"):
            row = db.execute("SELECT * FROM products WHERE id=? AND isActive=1", (fav.get("productId"),)).fetchone()
            if not row:
                continue
            in_stock = product_stock(db, row["id"]) > 0
            old_price = float(fav.get("lastKnownPrice", row["price"]))
            changed = False
            if row["price"] < old_price:
                notify(db, send_fcm, owner, "Sản phẩm yêu thích giảm giá",
                       f"{row['name']} giảm còn {int(row['price']):,}đ".replace(",", "."), "STOCK", row["id"])
                sent += 1
            if row["price"] != old_price:
                fav["lastKnownPrice"], changed = row["price"], True
            if in_stock and fav.get("lastInStock") is False:
                notify(db, send_fcm, owner, "Sản phẩm đã có hàng lại", f"{row['name']} hiện đã có hàng.", "STOCK", row["id"])
                sent += 1
            if fav.get("lastInStock") != in_stock:
                fav["lastInStock"], changed = in_stock, True
            if changed:
                save(db, "favorites", fid, owner, fav)
    return sent


def start_scheduler(connect, send_fcm_getter, interval=20):
    import threading

    def loop():
        while True:
            try:
                reminder_tick(connect, send_fcm_getter())
                if int(time.time()) % 60 < interval:
                    favorites_tick(connect, send_fcm_getter())
            except Exception as error:
                print(f"Scheduler error: {error}", flush=True)
            time.sleep(interval)
    threading.Thread(target=loop, daemon=True, name="pharma-scheduler").start()



PAYMENT_LABELS = {"PENDING": "Chờ thanh toán", "PAID": "Đã thanh toán", "FAILED": "Thanh toán thất bại",
                  "REFUNDED": "Đã hoàn tiền"}
MOMO_RETURN_HTML = (
    '<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" '
    'content="width=device-width,initial-scale=1"><title>An Tâm Pharma</title></head>'
    '<body style="font-family:sans-serif;text-align:center;padding:48px 16px">'
    '<h2>Đã nhận kết quả thanh toán</h2><p>Bạn có thể quay lại ứng dụng An Tâm Pharma.</p></body></html>')


def payment_of_order(db, order_id):
    """Giao dịch thanh toán mới nhất của một đơn: (id, ownerId, payload) hoặc None."""
    rows = [r for r in load(db, "payments") if r[2].get("orderId") == order_id]
    return rows[-1] if rows else None


def set_payment_status(db, send_fcm, pid, owner, payment, status, transaction_code=None):
    """Cập nhật trạng thái giao dịch + đơn hàng tương ứng và thông báo cho khách."""
    payment["paymentStatus"] = status
    payment["paymentStatusLabel"] = PAYMENT_LABELS.get(status, "Chờ thanh toán")
    if transaction_code:
        payment["transactionCode"] = transaction_code
    payment["paidAt"] = NOW() if status == "PAID" else None
    save(db, "payments", pid, owner, payment)
    order_owner, order = get(db, "orders", payment["orderId"])
    if order:
        order["paymentStatus"], order["updatedAt"] = status, NOW()
        if status == "PAID":
            order.setdefault("statusHistories", []).append({
                "id": "osh-" + secrets.token_hex(4), "status": order.get("orderStatus"),
                "statusLabel": "Đã xác nhận thanh toán", "note": f"Giao dịch {payment.get('transactionCode') or ''}".strip(),
                "changedByName": payment.get("paymentMethod"), "createdAt": NOW()})
        save(db, "orders", order["id"], order_owner, order)
    if status == "PAID":
        notify(db, send_fcm, owner, "Thanh toán thành công", f"Đơn {payment.get('orderCode')} đã được thanh toán.",
               "PAYMENT", payment["orderId"])
    elif status == "FAILED":
        notify(db, send_fcm, owner, "Thanh toán chưa thành công", f"Đơn {payment.get('orderCode')} chưa thanh toán được.",
               "PAYMENT", payment["orderId"])
    return payment


# ----------------------------------------------------------------------------- router
def handle(send, db, send_fcm, method, path, q, data, user):
    """Xử lý route mở rộng. Trả True nếu đã gửi phản hồi."""
    segs = [s for s in path.split("/") if s]
    if not segs:
        return False
    head = segs[0]
    roles = set(user["roles"]) if user else set()
    is_staff = bool(STAFF_ROLES & roles)

    def out(body, code=200):
        send(body, code)
        return True

    def fail(message, code=400):
        return out(api(None, message, code), code)

    def need_login():
        return fail("Vui lòng đăng nhập", 401)

    def need_staff():
        return fail("Bạn không có quyền thực hiện thao tác này", 403)

    # ---- hỗ trợ công khai
    if head == "support" and segs[1:] == ["faqs"] and method == "GET":
        return out(api(FAQS))
    if head == "support" and segs[1:] == ["info"] and method == "GET":
        return out(api({"hotline": hotline(), "email": "hotro@antam.local", "workingHours": "07:00 - 22:00 hằng ngày",
                        "bank": bank_info()}))

    # ---- sản phẩm: bổ sung rating/tồn kho
    if head == "products" and method == "GET" and len(segs) == 2 and segs[1] != "slug":
        row = db.execute("SELECT * FROM products WHERE id=?", (segs[1],)).fetchone()
        if not row or (not row["isActive"] and "ADMIN" not in roles):
            return fail("Không tìm thấy sản phẩm", 404)
        return out(api(decorate(db, [product_dict(db, row)], user)[0]))
    if head == "products" and method == "GET" and len(segs) == 3 and segs[1] == "slug":
        row = db.execute("SELECT * FROM products WHERE slug=?", (segs[2],)).fetchone()
        if not row or (not row["isActive"] and "ADMIN" not in roles):
            return fail("Không tìm thấy sản phẩm", 404)
        return out(api(decorate(db, [product_dict(db, row)], user)[0]))

    # ---- đánh giá nâng cao
    if head == "reviews":
        if method == "GET" and len(segs) == 3 and segs[1] == "products":
            pid = segs[2]
            all_reviews = [p for _, _, p in load(db, "reviews") if p.get("productId") == pid and p.get("isVisible", True)]
            all_reviews.sort(key=lambda x: x["createdAt"], reverse=True)
            dist = {str(s): sum(1 for r in all_reviews if int(r.get("rating", 0)) == s) for s in range(1, 6)}
            reviews = [r for r in all_reviews if not q.get("rating") or int(r["rating"]) == int(q["rating"])]
            body = page_of(reviews, q)
            body["summary"] = {"count": len(all_reviews), "distribution": dist,
                               "average": round(sum(int(r["rating"]) for r in all_reviews) / len(all_reviews), 1) if all_reviews else 0}
            return out(api(body))
        if method == "POST" and len(segs) == 1:
            if not user:
                return need_login()
            product = db.execute("SELECT id,name FROM products WHERE id=?", (data.get("productId"),)).fetchone()
            rating = int(data.get("rating", 0) or 0)
            if not product or not 1 <= rating <= 5:
                return fail("Sản phẩm hoặc số sao đánh giá không hợp lệ")
            if not any(p.get("userId") == user["id"] and any(i.get("productId") == product["id"] for i in p.get("items", []))
                       for _, _, p in load(db, "orders", user["id"])) and not (roles & {"ADMIN"}):
                return fail("Bạn cần mua sản phẩm này trước khi đánh giá", 403)
            rid = "review-" + secrets.token_hex(6)
            review = {"id": rid, "userId": user["id"], "userFullName": user.get("fullName"), "userAvatarUrl": user.get("avatarUrl"),
                      "productId": product["id"], "productName": product["name"], "orderId": data.get("orderId"),
                      "rating": rating, "comment": data.get("comment"), "imageUrls": list(data.get("imageUrls") or [])[:5],
                      "isVisible": True, "createdAt": NOW(), "updatedAt": NOW()}
            save(db, "reviews", rid, user["id"], review)
            return out(api(review), 201)
        if method == "GET" and segs[1:] == ["staff"]:
            if not is_staff:
                return need_staff()
            items = [p for _, _, p in load(db, "reviews")]
            if q.get("replied") in ("true", "false"):
                items = [r for r in items if bool(r.get("staffReply")) == (q["replied"] == "true")]
            items.sort(key=lambda x: x["createdAt"], reverse=True)
            return out(api(page_of(items, q)))
        if method in ("PUT", "POST") and len(segs) == 3 and segs[2] == "reply":
            if not is_staff:
                return need_staff()
            owner, review = get(db, "reviews", segs[1])
            if not review:
                return fail("Không tìm thấy đánh giá", 404)
            review.update({"staffReply": str(data.get("reply", "")).strip(), "staffReplyBy": user.get("fullName"), "staffReplyAt": NOW()})
            save(db, "reviews", segs[1], owner, review)
            if owner and review["staffReply"]:
                notify(db, send_fcm, owner, "Nhà thuốc đã phản hồi đánh giá của bạn", review["staffReply"][:120], "REVIEW", review["productId"])
            return out(api(review))

    # ---- đơn hàng: mua lại, hóa đơn, thuốc thường dùng, hoàn tiền
    if head == "orders":
        if method == "GET" and segs[1:] == ["frequent-products"]:
            if not user:
                return need_login()
            stats = {}
            for _, _, order in load(db, "orders", user["id"]):
                if order.get("orderStatus") == "CANCELLED":
                    continue
                for item in order.get("items", []):
                    s = stats.setdefault(item["productId"], {"dates": [], "quantity": 0})
                    s["dates"].append(order["createdAt"])
                    s["quantity"] += int(item.get("quantity", 1))
            result = []
            for pid, s in stats.items():
                row = db.execute("SELECT * FROM products WHERE id=? AND isActive=1", (pid,)).fetchone()
                if not row:
                    continue
                dates = sorted(datetime.fromisoformat(d) for d in s["dates"])
                gaps = [(b - a).days for a, b in zip(dates, dates[1:]) if (b - a).days > 0]
                interval = round(sum(gaps) / len(gaps)) if gaps else 30
                last = dates[-1]
                product = product_dict(db, row)
                result.append({"product": product, "timesPurchased": len(dates), "totalQuantity": s["quantity"],
                               "lastPurchasedAt": last.isoformat(), "averageIntervalDays": interval,
                               "nextSuggestedAt": (last + timedelta(days=interval)).isoformat(),
                               "isDue": datetime.now(timezone.utc) >= last + timedelta(days=interval)})
            result.sort(key=lambda x: (-x["timesPurchased"], x["lastPurchasedAt"]))
            return out(api(result))
        if len(segs) == 3 and segs[2] == "reorder" and method == "POST":
            if not user:
                return need_login()
            owner, order = get(db, "orders", segs[1])
            if not order or owner != user["id"]:
                return fail("Không tìm thấy đơn hàng", 404)
            added, skipped = 0, []
            for item in order.get("items", []):
                row = db.execute("SELECT * FROM products WHERE id=? AND isActive=1", (item["productId"],)).fetchone()
                if not row:
                    skipped.append(item.get("productName"))
                    continue
                product = product_dict(db, row)
                existing = next(((cid, p) for cid, _, p in load(db, "cart", user["id"]) if p.get("productId") == product["id"]), None)
                quantity = int(item.get("quantity", 1))
                if existing:
                    cid, payload = existing
                    payload["quantity"] += quantity
                    payload["totalPrice"] = payload["unitPrice"] * payload["quantity"]
                else:
                    cid = "ci-" + secrets.token_hex(6)
                    payload = {"id": cid, "productId": product["id"], "productName": product["name"], "productSlug": product["slug"],
                               "productImage": product.get("thumbnailUrl"), "unit": product["unit"], "unitPrice": product["price"],
                               "quantity": quantity, "totalPrice": product["price"] * quantity,
                               "requiresPrescription": product["requiresPrescription"], "isActive": True}
                save(db, "cart", cid, user["id"], payload)
                added += 1
            return out(api({"addedCount": added, "skipped": skipped,
                            "message": f"Đã thêm {added} sản phẩm vào giỏ hàng"}))
        if len(segs) == 3 and segs[2] == "invoice" and method == "GET":
            if not user:
                return need_login()
            owner, order = get(db, "orders", segs[1])
            if not order or (owner != user["id"] and not is_staff):
                return fail("Không tìm thấy đơn hàng", 404)
            return out(api({
                "invoiceNumber": "HD" + order["orderCode"][2:], "orderId": order["id"], "orderCode": order["orderCode"],
                "issuedAt": order.get("updatedAt", order["createdAt"]), "seller": "Nhà thuốc An Tâm",
                "pharmacyName": order.get("pharmacyName"), "customerName": order.get("receiverName"),
                "customerPhone": order.get("receiverPhone"), "shippingAddress": order.get("shippingAddress"),
                "items": order.get("items", []), "subtotal": order.get("totalAmount", 0),
                "discount": order.get("discountAmount", 0), "shippingFee": order.get("shippingFee", 0),
                "total": order.get("finalAmount", 0), "paymentMethod": order.get("paymentMethod"),
                "paymentStatus": order.get("paymentStatus"), "orderStatus": order.get("orderStatusLabel"),
                "voucherCode": order.get("voucherCode"), "pointsEarned": order.get("pointsEarned", 0)}))
        if len(segs) == 3 and segs[1] == "admin" and method == "GET":
            if "ADMIN" not in roles:
                return need_staff()
            owner, order = get(db, "orders", segs[2])
            if not order:
                return fail("Không tìm thấy đơn hàng", 404)
            return out(api(order))
        if len(segs) == 4 and segs[1] == "admin" and segs[3] == "confirm-payment" and method == "POST":
            if "ADMIN" not in roles:
                return need_staff()
            owner, order = get(db, "orders", segs[2])
            if not order:
                return fail("Không tìm thấy đơn hàng", 404)
            if order.get("orderStatus") == "CANCELLED":
                return fail("Đơn hàng đã bị hủy", 409)
            if order.get("paymentStatus") in ("PAID", "REFUNDED"):
                return fail("Đơn hàng đã được xác nhận thanh toán", 409)
            existing = payment_of_order(db, order["id"])
            if existing:
                pid, pay_owner, payment = existing
            else:
                pid, pay_owner = "pay-" + secrets.token_hex(5), owner
                payment = {"id": pid, "orderId": order["id"], "orderCode": order["orderCode"], "amount": order["finalAmount"],
                           "paymentMethod": order.get("paymentMethod"), "transactionCode": None, "createdAt": NOW()}
            code = str(data.get("transactionCode") or "").strip() or f"ADMIN-{order['orderCode']}"
            set_payment_status(db, send_fcm, pid, pay_owner, payment, "PAID", code)
            return out(api(get(db, "orders", segs[2])[1]))
        if len(segs) == 4 and segs[1] == "admin" and segs[3] == "refund" and method == "POST":
            if "ADMIN" not in roles:
                return need_staff()
            owner, order = get(db, "orders", segs[2])
            if not order:
                return fail("Không tìm thấy đơn hàng", 404)
            if order.get("paymentStatus") != "PAID" and order.get("orderStatus") != "CANCELLED":
                return fail("Chỉ hoàn tiền cho đơn đã thanh toán hoặc đã hủy", 409)
            if order.get("paymentStatus") == "REFUNDED":
                return fail("Đơn hàng đã được hoàn tiền", 409)
            order["paymentStatus"], order["refundReason"], order["refundedAt"] = "REFUNDED", data.get("reason"), NOW()
            order["updatedAt"] = NOW()
            order.setdefault("statusHistories", []).append({
                "id": "osh-" + secrets.token_hex(4), "status": order["orderStatus"], "statusLabel": "Đã hoàn tiền",
                "note": data.get("reason"), "changedByName": user.get("fullName"), "createdAt": NOW()})
            save(db, "orders", order["id"], owner, order)
            for pay_id, pay_owner, pay in load(db, "payments"):
                if pay.get("orderId") == order["id"]:
                    pay["paymentStatus"], pay["paymentStatusLabel"] = "REFUNDED", "Đã hoàn tiền"
                    save(db, "payments", pay_id, pay_owner, pay)
            notify(db, send_fcm, owner, "Đơn hàng đã được hoàn tiền", f"Đơn {order['orderCode']} đã hoàn tiền.", "ORDER", order["id"])
            return out(api(order))

    # ---- giỏ hàng: mọi thao tác ghi trả về GIỎ HÀNG ĐẦY ĐỦ (app đọc phản hồi như CartModel)
    if head == "cart":
        if not user:
            return need_login()
        uid = user["id"]
        if method == "DELETE" and len(segs) == 1:
            db.execute("DELETE FROM records WHERE kind='cart' AND ownerId=?", (uid,))
            return out(api(cart_payload(db, uid)))
        if len(segs) >= 2 and segs[1] == "items":
            if method == "POST" and len(segs) == 2:
                row = db.execute("SELECT * FROM products WHERE id=?", (str(data.get("productId", "")),)).fetchone()
                if not row or not row["isActive"]:
                    return fail("Không tìm thấy sản phẩm", 404)
                try:
                    quantity = max(1, int(data.get("quantity", 1) or 1))
                except (TypeError, ValueError):
                    return fail("Số lượng không hợp lệ")
                product = product_dict(db, row)
                same = next(((cid, p) for cid, _, p in load(db, "cart", uid) if p.get("productId") == product["id"]), None)
                if same:  # cùng sản phẩm: cộng dồn số lượng thay vì tạo dòng mới
                    cid, payload = same
                    payload["quantity"] += quantity
                else:
                    cid = "ci-" + secrets.token_hex(6)
                    payload = {"id": cid, "productId": product["id"], "productName": product["name"], "productSlug": product["slug"],
                               "productImage": product.get("thumbnailUrl"), "unit": product["unit"], "unitPrice": product["price"],
                               "quantity": quantity, "requiresPrescription": product["requiresPrescription"], "isActive": True}
                payload["totalPrice"] = payload["unitPrice"] * payload["quantity"]
                save(db, "cart", cid, uid, payload)
                return out(api(cart_payload(db, uid)), 201)
            if len(segs) >= 3:
                cid = segs[2]
                owner, payload = get(db, "cart", cid)
                if method == "DELETE" and len(segs) == 3:
                    remove(db, "cart", cid, uid)
                    return out(api(cart_payload(db, uid)))
                if not payload or owner != uid:
                    return fail("Không tìm thấy sản phẩm trong giỏ", 404)
                if method in ("PUT", "PATCH") and len(segs) == 3:
                    try:
                        payload["quantity"] = max(1, int(data.get("quantity", payload["quantity"]) or 1))
                    except (TypeError, ValueError):
                        return fail("Số lượng không hợp lệ")
                elif method in ("PUT", "PATCH", "POST") and len(segs) == 4 and segs[3] in ("increase", "decrease"):
                    payload["quantity"] = max(1, int(payload["quantity"]) + (1 if segs[3] == "increase" else -1))
                else:
                    return False
                payload["totalPrice"] = payload["unitPrice"] * payload["quantity"]
                save(db, "cart", cid, uid, payload)
                return out(api(cart_payload(db, uid)))

    # ---- ví MoMo (sandbox mặc định)
    if head == "payments" and segs[1:2] == ["momo"]:
        action = segs[2] if len(segs) > 2 else ""
        if action == "return" and method == "GET":
            return out(MOMO_RETURN_HTML)
        if action == "ipn" and method == "POST":
            if not momo.verify_ipn(data):
                return fail("Chữ ký không hợp lệ", 400)
            found = [r for r in load(db, "payments") if r[2].get("momoOrderId") == data.get("orderId")]
            if not found:
                return fail("Không tìm thấy giao dịch", 404)
            pid, owner, payment = found[-1]
            if payment["paymentStatus"] != "PAID":
                if int(data.get("resultCode", -1)) == 0 and int(data.get("amount", 0)) == int(float(payment["amount"])):
                    set_payment_status(db, send_fcm, pid, owner, payment, "PAID", str(data.get("transId", "")))
                elif int(data.get("resultCode", -1)) not in momo.PENDING_CODES:
                    set_payment_status(db, send_fcm, pid, owner, payment, "FAILED")
            return out(api({"resultCode": 0}))
        if not user:
            return need_login()
        if action == "create-payment" and method == "POST":
            owner, order = get(db, "orders", data.get("orderId", ""))
            if not order or owner != user["id"]:
                return fail("Không tìm thấy đơn hàng", 404)
            if order.get("orderStatus") == "CANCELLED":
                return fail("Đơn hàng đã bị hủy", 409)
            if order.get("paymentStatus") == "PAID":
                return fail("Đơn hàng đã được thanh toán", 409)
            existing = payment_of_order(db, order["id"])
            if existing:
                pid, _, payment = existing
            else:
                pid = "pay-" + secrets.token_hex(5)
                payment = {"id": pid, "orderId": order["id"], "orderCode": order["orderCode"], "amount": order["finalAmount"],
                           "transactionCode": None, "createdAt": NOW()}
            try:
                created = momo.create_payment(order["orderCode"], int(float(order["finalAmount"])), f"Thanh toan don {order['orderCode']}")
            except momo.MomoError as error:
                return fail(str(error), 502)
            payment.update(created)
            payment["paymentMethod"] = "MOMO"
            order["paymentMethod"] = "MOMO"
            save(db, "orders", order["id"], owner, order)
            set_payment_status(db, send_fcm, pid, owner, payment, "PENDING")
            return out(api({"paymentId": pid, **created, "amount": payment["amount"], "orderCode": order["orderCode"],
                            "sandbox": momo.config()["isSandbox"]}), 201)
        if action == "verify" and method == "POST":
            owner, order = get(db, "orders", data.get("orderId", ""))
            if not order or (owner != user["id"] and "ADMIN" not in roles):
                return fail("Không tìm thấy đơn hàng", 404)
            existing = payment_of_order(db, order["id"])
            if not existing or not existing[2].get("momoOrderId"):
                return fail("Đơn hàng chưa có giao dịch MoMo", 404)
            pid, pay_owner, payment = existing
            if payment["paymentStatus"] == "PAID":
                return out(api({"payment": payment, "resultCode": 0, "message": "Đã thanh toán", "status": "PAID"}))
            try:
                result = momo.query_payment(payment["momoOrderId"])
            except momo.MomoError as error:
                return fail(str(error), 502)
            code = int(result.get("resultCode", -1))
            if code == 0:
                if int(result.get("amount", 0)) != int(float(payment["amount"])):
                    return fail("Số tiền thanh toán không khớp với đơn hàng", 409)
                set_payment_status(db, send_fcm, pid, pay_owner, payment, "PAID", str(result.get("transId", "")))
            elif code not in momo.PENDING_CODES:
                set_payment_status(db, send_fcm, pid, pay_owner, payment, "FAILED")
            return out(api({"payment": payment, "resultCode": code, "message": result.get("message"),
                            "status": payment["paymentStatus"]}))

    # ---- thanh toán chuyển khoản QR (VietQR)
    if head == "payments" and segs[1:] == ["bank-qr"] and method == "GET":
        if not user:
            return need_login()
        owner, order = get(db, "orders", q.get("orderId", ""))
        if not order or owner != user["id"]:
            return fail("Không tìm thấy đơn hàng", 404)
        amount = int(float(order.get("finalAmount", 0)))
        memo = order["orderCode"]
        bank = bank_info()
        qr = (f"https://img.vietqr.io/image/{bank['bankId']}-{bank['accountNo']}-compact2.png"
              f"?amount={amount}&addInfo={memo}&accountName={bank['accountName'].replace(' ', '%20')}")
        return out(api({**bank, "amount": amount, "transferContent": memo, "qrUrl": qr, "orderCode": memo,
                        "qrContent": vietqr_payload(bank["bankId"], bank["accountNo"], amount, memo),
                        "isSampleAccount": bank["accountNo"] == _BANK_DEFAULTS["accountNo"]}))

    # ---- yêu thích
    if head == "favorites":
        if not user:
            return need_login()
        if method == "GET" and len(segs) == 1:
            favs = sorted(load(db, "favorites", user["id"]), key=lambda x: x[2]["createdAt"], reverse=True)
            items = []
            for _, _, fav in favs:
                row = db.execute("SELECT * FROM products WHERE id=? AND isActive=1", (fav["productId"],)).fetchone()
                if row:
                    items.append(product_dict(db, row))
            return out(api(decorate(db, items, user)))
        if method == "GET" and segs[1:] == ["ids"]:
            return out(api([p["productId"] for _, _, p in load(db, "favorites", user["id"])]))
        if method == "POST" and len(segs) == 1:
            row = db.execute("SELECT * FROM products WHERE id=?", (data.get("productId"),)).fetchone()
            if not row:
                return fail("Không tìm thấy sản phẩm", 404)
            fid = f"fav-{user['id']}-{row['id']}"
            if get(db, "favorites", fid)[1] is None:
                save(db, "favorites", fid, user["id"], {
                    "id": fid, "productId": row["id"], "createdAt": NOW(),
                    "lastKnownPrice": row["price"], "lastInStock": product_stock(db, row["id"]) > 0})
            return out(api(decorate(db, [product_dict(db, row)], user)[0]), 201)
        if method == "DELETE" and len(segs) == 2:
            remove(db, "favorites", f"fav-{user['id']}-{segs[1]}", user["id"])
            return out(api(None))

    # ---- nhắc uống thuốc (đồng bộ từ SQLite trên thiết bị)
    if head == "reminders":
        if not user:
            return need_login()
        if method == "GET" and segs[1:] == ["logs"]:
            logs = [p for _, _, p in load(db, "reminder_logs", user["id"])]
            if q.get("from"):
                logs = [x for x in logs if x["date"] >= q["from"]]
            if q.get("to"):
                logs = [x for x in logs if x["date"] <= q["to"]]
            return out(api(logs))
        if method == "GET" and len(segs) == 1:
            return out(api([p for _, _, p in load(db, "reminders", user["id"])]))
        if method in ("POST", "PUT") and len(segs) == 1 or (method == "PUT" and len(segs) == 2):
            rid = str(data.get("id") or (segs[1] if len(segs) == 2 else "rem-" + secrets.token_hex(6)))
            if not str(data.get("medicineName", "")).strip():
                return fail("Vui lòng nhập tên thuốc")
            times = [t for t in data.get("times", []) if re.fullmatch(r"([01]\d|2[0-3]):[0-5]\d", str(t))]
            if not times:
                return fail("Vui lòng chọn ít nhất một giờ uống thuốc (HH:mm)")
            owner, old = get(db, "reminders", rid)
            if old and owner != user["id"]:
                return fail("Không tìm thấy lịch nhắc", 404)
            reminder = {**(old or {}), **data, "id": rid, "times": sorted(set(times)),
                        "repeat": "WEEKLY" if data.get("repeat") == "WEEKLY" else "DAILY",
                        "weekdays": [int(d) for d in data.get("weekdays", []) if 1 <= int(d) <= 7],
                        "isActive": bool(data.get("isActive", True)), "createdAt": (old or {}).get("createdAt", NOW()),
                        "updatedAt": NOW()}
            save(db, "reminders", rid, user["id"], reminder)
            return out(api(reminder), 200 if old else 201)
        if method == "POST" and len(segs) == 3 and segs[2] == "logs":
            owner, reminder = get(db, "reminders", segs[1])
            if not reminder or owner != user["id"]:
                return fail("Không tìm thấy lịch nhắc", 404)
            date, tm = str(data.get("date", "")), str(data.get("time", ""))
            lid = f"{segs[1]}:{date}:{tm}"
            log = {"id": lid, "reminderId": segs[1], "medicineName": reminder["medicineName"], "date": date, "time": tm,
                   "taken": bool(data.get("taken", True)), "recordedAt": NOW()}
            save(db, "reminder_logs", lid, user["id"], log)
            return out(api(log), 201)
        if method == "DELETE" and len(segs) == 2:
            remove(db, "reminders", segs[1], user["id"])
            return out(api(None))

    # ---- hồ sơ sức khỏe gia đình
    if head == "health":
        if not user:
            return need_login()
        sub = segs[1] if len(segs) > 1 else ""
        if sub == "members":
            if method == "GET" and len(segs) == 2:
                members = [p for _, _, p in load(db, "health_members", user["id"])]
                if not members:
                    me = {"id": "hm-" + secrets.token_hex(5), "name": user.get("fullName") or "Tôi", "relation": "SELF",
                          "gender": None, "birthDate": None, "heightCm": None, "weightKg": None, "allergies": "",
                          "conditions": "", "note": "", "createdAt": NOW()}
                    save(db, "health_members", me["id"], user["id"], me)
                    members = [me]
                return out(api(members))
            if method in ("POST", "PUT") and (len(segs) == 2 or len(segs) == 3):
                mid = str(data.get("id") or (segs[2] if len(segs) == 3 else "hm-" + secrets.token_hex(5)))
                if not str(data.get("name", "")).strip():
                    return fail("Vui lòng nhập tên thành viên")
                owner, old = get(db, "health_members", mid)
                if old and owner != user["id"]:
                    return fail("Không tìm thấy hồ sơ", 404)
                member = {**(old or {}), **data, "id": mid, "createdAt": (old or {}).get("createdAt", NOW()), "updatedAt": NOW()}
                save(db, "health_members", mid, user["id"], member)
                return out(api(member), 200 if old else 201)
            if method == "DELETE" and len(segs) == 3:
                owner, member = get(db, "health_members", segs[2])
                if not member or owner != user["id"]:
                    return fail("Không tìm thấy hồ sơ", 404)
                if member.get("relation") == "SELF":
                    return fail("Không thể xóa hồ sơ của bản thân", 409)
                remove(db, "health_members", segs[2], user["id"])
                for mid, _, metric in load(db, "health_metrics", user["id"]):
                    if metric.get("memberId") == segs[2]:
                        remove(db, "health_metrics", mid)
                return out(api(None))
            if len(segs) == 4 and segs[3] == "metrics":
                owner, member = get(db, "health_members", segs[2])
                if not member or owner != user["id"]:
                    return fail("Không tìm thấy hồ sơ", 404)
                if method == "GET":
                    items = [p for _, _, p in load(db, "health_metrics", user["id"]) if p.get("memberId") == segs[2]]
                    if q.get("type"):
                        items = [m for m in items if m.get("type") == q["type"]]
                    items.sort(key=lambda m: m.get("measuredAt", ""), reverse=True)
                    return out(api(items))
                if method == "POST":
                    mtype = str(data.get("type", "")).upper()
                    if mtype not in ("WEIGHT", "BLOOD_PRESSURE", "GLUCOSE"):
                        return fail("Loại chỉ số không hợp lệ")
                    mid = str(data.get("id") or "hmt-" + secrets.token_hex(6))
                    metric = {**data, "id": mid, "memberId": segs[2], "type": mtype, "measuredAt": data.get("measuredAt", NOW()),
                              "createdAt": NOW()}
                    save(db, "health_metrics", mid, user["id"], metric)
                    return out(api(metric), 201)
        if sub == "metrics":
            if method == "GET" and len(segs) == 2:
                return out(api([p for _, _, p in load(db, "health_metrics", user["id"])]))
            if method == "DELETE" and len(segs) == 3:
                remove(db, "health_metrics", segs[2], user["id"])
                return out(api(None))

    # ---- điểm thưởng
    if head == "loyalty":
        if not user:
            return need_login()
        if method == "GET" and len(segs) == 1:
            return out(api(loyalty_summary(db, user["id"])))
        if method == "POST" and segs[1:] == ["redeem"]:
            reward = next((r for r in REWARDS if r["id"] == data.get("rewardId")), None)
            if not reward:
                return fail("Phần thưởng không tồn tại", 404)
            summary = loyalty_summary(db, user["id"])
            if summary["points"] < reward["points"]:
                return fail("Bạn chưa đủ điểm để đổi phần thưởng này", 409)
            code = "DIEM" + secrets.token_hex(3).upper()
            vid = "voucher-" + secrets.token_hex(5)
            voucher = {"id": vid, "code": code, "name": reward["name"],
                       "description": f"Đổi từ {reward['points']} điểm thưởng", "discountType": "FIXED_AMOUNT",
                       "discountValue": reward["discountValue"], "maxDiscountAmount": None,
                       "minOrderAmount": reward["minOrderAmount"], "usageLimit": 1, "usedCount": 0, "isActive": True,
                       "ownerUserId": user["id"], "createdAt": NOW()}
            save(db, "vouchers", vid, None, voucher)
            add_points(db, user["id"], -reward["points"], f"Đổi {reward['name']}", "REDEEM")
            return out(api({"voucher": voucher, "summary": loyalty_summary(db, user["id"])}), 201)
    if head == "admin" and len(segs) >= 4 and segs[1] == "users" and segs[3] in ("points", "orders") and "ADMIN" in roles:
        uid = segs[2]
        if not db.execute("SELECT 1 FROM users WHERE id=?", (uid,)).fetchone():
            return fail("Không tìm thấy người dùng", 404)
        if segs[3] == "orders" and method == "GET":
            orders = [p for _, _, p in load(db, "orders", uid)]
            orders.sort(key=lambda x: x["createdAt"], reverse=True)
            return out(api(page_of(orders, q)))
        if segs[3] == "points" and method == "GET":
            return out(api(loyalty_summary(db, uid)))
        if segs[3] == "points" and method == "POST":
            delta = int(data.get("delta", 0) or 0)
            if delta == 0 or not str(data.get("reason", "")).strip():
                return fail("Nhập số điểm khác 0 và lý do")
            if loyalty_summary(db, uid)["points"] + delta < 0:
                return fail("Không thể trừ quá số điểm hiện có", 409)
            add_points(db, uid, delta, str(data["reason"]).strip(), "ADJUST")
            notify(db, send_fcm, uid, "Điểm thưởng được điều chỉnh", f"{'+' if delta > 0 else ''}{delta} điểm: {data['reason']}", "LOYALTY")
            return out(api(loyalty_summary(db, uid)))

    # ---- chat dược sĩ + chatbot
    if head == "chat":
        if not user:
            return need_login()
        sub = segs[1] if len(segs) > 1 else ""
        if sub == "bot" and method == "POST":
            return out(api(bot_reply(db, user, data.get("message", ""))))
        if sub == "presence":
            if method == "PUT":
                if not is_staff:
                    return need_staff()
                save(db, "presence", user["id"], user["id"], {"id": user["id"], "online": bool(data.get("online", True)), "lastSeen": NOW()})
                return out(api(None))
            limit = (datetime.now(timezone.utc) - timedelta(minutes=2)).isoformat()
            online = [p for _, _, p in load(db, "presence") if p.get("online") and p["lastSeen"] >= limit]
            return out(api({"pharmacistOnline": bool(online), "onlineCount": len(online)}))
        if sub == "my-conversation" and method == "GET":
            cid = "conv-" + user["id"]
            owner, conv = get(db, "chat_conversations", cid)
            if not conv:
                conv = {"id": cid, "customerId": user["id"], "customerName": user.get("fullName"), "lastMessage": None,
                        "lastMessageAt": None, "unreadForStaff": 0, "unreadForCustomer": 0, "notes": [], "createdAt": NOW()}
                save(db, "chat_conversations", cid, user["id"], conv)
            return out(api(conv))
        if sub == "conversations" and len(segs) == 2 and method == "GET":
            if not is_staff:
                return need_staff()
            convs = [p for _, _, p in load(db, "chat_conversations") if p.get("lastMessageAt")]
            convs.sort(key=lambda c: c["lastMessageAt"], reverse=True)
            for conv in convs:
                conv["notes"] = conv.get("notes", [])
            return out(api(convs))
        if sub == "conversations" and len(segs) >= 3:
            cid = segs[2]
            owner, conv = get(db, "chat_conversations", cid)
            if not conv or (conv["customerId"] != user["id"] and not is_staff):
                return fail("Không tìm thấy cuộc trò chuyện", 404)
            action = segs[3] if len(segs) > 3 else ""
            if action == "messages" and method == "GET":
                msgs = [p for _, _, p in load(db, "chat_messages", cid)]
                if q.get("after"):
                    msgs = [m for m in msgs if m["createdAt"] > q["after"]]
                return out(api(msgs))
            if action == "messages" and method == "POST":
                content = str(data.get("content", "")).strip()
                if not content and not data.get("attachmentUrl") and not data.get("productId"):
                    return fail("Tin nhắn trống")
                role = "CUSTOMER" if conv["customerId"] == user["id"] and not is_staff else \
                    ("ADMIN" if "ADMIN" in roles else "PHARMACIST")
                product_name = None
                if data.get("productId"):
                    row = db.execute("SELECT name FROM products WHERE id=?", (data["productId"],)).fetchone()
                    product_name = row["name"] if row else None
                mid = "msg-" + secrets.token_hex(6)
                message = {"id": mid, "conversationId": cid, "senderId": user["id"], "senderRole": role,
                           "senderName": user.get("fullName"), "content": content, "attachmentUrl": data.get("attachmentUrl"),
                           "attachmentType": data.get("attachmentType"), "productId": data.get("productId"),
                           "productName": product_name, "createdAt": NOW()}
                save(db, "chat_messages", mid, cid, message)
                preview = content or ("[Hình ảnh/tệp]" if data.get("attachmentUrl") else f"[Sản phẩm] {product_name}")
                conv["lastMessage"], conv["lastMessageAt"] = preview[:120], message["createdAt"]
                if role == "CUSTOMER":
                    conv["unreadForStaff"] = int(conv.get("unreadForStaff", 0)) + 1
                else:
                    conv["unreadForCustomer"] = int(conv.get("unreadForCustomer", 0)) + 1
                    notify(db, send_fcm, conv["customerId"], "Dược sĩ đã phản hồi", preview[:100], "CONSULTATION", cid)
                save(db, "chat_conversations", cid, conv["customerId"], conv)
                return out(api(message), 201)
            if action == "read" and method == "PUT":
                conv["unreadForStaff" if is_staff else "unreadForCustomer"] = 0
                save(db, "chat_conversations", cid, conv["customerId"], conv)
                return out(api(conv))
            if action == "notes":
                if not is_staff:
                    return need_staff()
                if method == "GET":
                    return out(api(conv.get("notes", [])))
                if method == "POST":
                    text = str(data.get("content", "")).strip()
                    if not text:
                        return fail("Nhập nội dung ghi chú")
                    conv.setdefault("notes", []).append({"id": "note-" + secrets.token_hex(4), "content": text,
                                                         "authorName": user.get("fullName"), "createdAt": NOW()})
                    save(db, "chat_conversations", cid, conv["customerId"], conv)
                    return out(api(conv["notes"]), 201)

    # ---- hỗ trợ khách hàng: ticket
    if head == "support" and len(segs) >= 2 and segs[1] in ("tickets", "staff"):
        if not user:
            return need_login()
        if segs[1] == "tickets":
            if method == "GET" and len(segs) == 2:
                items = [p for _, _, p in load(db, "support_tickets", user["id"])]
                items.sort(key=lambda t: t["updatedAt"], reverse=True)
                return out(api(items))
            if method == "POST" and len(segs) == 2:
                subject, content = str(data.get("subject", "")).strip(), str(data.get("content", "")).strip()
                if not subject or not content:
                    return fail("Vui lòng nhập tiêu đề và nội dung")
                tid = "tk-" + secrets.token_hex(6)
                ticket = {"id": tid, "code": "TK" + tid[-6:].upper(), "userId": user["id"], "userName": user.get("fullName"),
                          "category": data.get("category", "OTHER"), "subject": subject, "orderId": data.get("orderId"),
                          "status": "OPEN", "statusLabel": "Đang chờ xử lý", "createdAt": NOW(), "updatedAt": NOW(),
                          "messages": [{"id": "tm-" + secrets.token_hex(4), "senderRole": "CUSTOMER",
                                        "senderName": user.get("fullName"), "content": content, "createdAt": NOW()}]}
                save(db, "support_tickets", tid, user["id"], ticket)
                return out(api(ticket), 201)
            if len(segs) >= 3:
                owner, ticket = get(db, "support_tickets", segs[2])
                if not ticket or (owner != user["id"] and not is_staff):
                    return fail("Không tìm thấy yêu cầu hỗ trợ", 404)
                if method == "GET" and len(segs) == 3:
                    return out(api(ticket))
                if method == "POST" and len(segs) == 4 and segs[3] == "messages":
                    content = str(data.get("content", "")).strip()
                    if not content:
                        return fail("Tin nhắn trống")
                    ticket["messages"].append({"id": "tm-" + secrets.token_hex(4), "senderRole": "STAFF" if is_staff and owner != user["id"] else "CUSTOMER",
                                               "senderName": user.get("fullName"), "content": content, "createdAt": NOW()})
                    ticket["updatedAt"] = NOW()
                    if ticket["status"] == "RESOLVED":
                        ticket["status"], ticket["statusLabel"] = "OPEN", "Đang chờ xử lý"
                    save(db, "support_tickets", ticket["id"], owner, ticket)
                    return out(api(ticket), 201)
        if segs[1] == "staff":
            if not is_staff:
                return need_staff()
            if method == "GET" and segs[2:] == ["tickets"]:
                items = [p for _, _, p in load(db, "support_tickets")]
                if q.get("status"):
                    items = [t for t in items if t["status"] == q["status"]]
                items.sort(key=lambda t: t["updatedAt"], reverse=True)
                return out(api(items))
            if method == "PUT" and len(segs) == 4 and segs[2] == "tickets":
                owner, ticket = get(db, "support_tickets", segs[3])
                if not ticket:
                    return fail("Không tìm thấy yêu cầu hỗ trợ", 404)
                labels = {"OPEN": "Đang chờ xử lý", "IN_PROGRESS": "Đang xử lý", "RESOLVED": "Đã giải quyết", "CLOSED": "Đã đóng"}
                status = data.get("status", ticket["status"])
                if status not in labels:
                    return fail("Trạng thái không hợp lệ")
                ticket["status"], ticket["statusLabel"], ticket["updatedAt"] = status, labels[status], NOW()
                reply = str(data.get("reply", "")).strip()
                if reply:
                    ticket["messages"].append({"id": "tm-" + secrets.token_hex(4), "senderRole": "STAFF",
                                               "senderName": user.get("fullName"), "content": reply, "createdAt": NOW()})
                save(db, "support_tickets", ticket["id"], owner, ticket)
                notify(db, send_fcm, owner, f"Yêu cầu {ticket['code']} đã cập nhật", reply[:100] or labels[status], "SUPPORT", ticket["id"])
                return out(api(ticket))

    return False
