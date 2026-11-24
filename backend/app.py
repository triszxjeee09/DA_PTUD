"""Small, persistent REST backend for the An Tam Pharma graduation project."""
from __future__ import annotations

import hashlib
import hmac
import json
import mimetypes
import os
import re
import secrets
import sqlite3
from email import policy
from email.parser import BytesParser
from datetime import datetime, timedelta, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

ROOT = Path(__file__).resolve().parent
import sys
sys.path.insert(0, str(ROOT))
import extras  # tính năng mở rộng: yêu thích, nhắc thuốc, chat, điểm thưởng...
DB_PATH = Path(os.environ.get("PHARMA_DB", ROOT / "data" / "an_tam_pharma.sqlite3"))
DB_PATH.parent.mkdir(parents=True, exist_ok=True)
UPLOAD_DIR = Path(os.environ.get("PHARMA_UPLOADS", ROOT / "uploads"))
ALLOWED_UPLOAD_EXT = {".jpg", ".jpeg", ".png", ".webp", ".pdf"}
BUILD_VERSION = "2026-11-24-r6"  # tăng số này mỗi lần sửa backend để biết đang chạy bản nào
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
NOW = lambda: datetime.now(timezone.utc).isoformat()
FCM = None


def configure_firebase():
    global FCM
    credential_path = os.environ.get("FIREBASE_SERVICE_ACCOUNT_FILE", "").strip()
    if not credential_path:
        return False
    try:
        import firebase_admin
        from firebase_admin import credentials, messaging
        try:
            firebase_admin.get_app()
        except ValueError:
            firebase_admin.initialize_app(credentials.Certificate(credential_path))
        FCM = messaging
        print("Firebase Admin push is configured", flush=True)
        return True
    except Exception as error:
        FCM = None
        print(f"Firebase Admin is unavailable: {error}", flush=True)
        return False


def send_fcm(tokens, title, content, data=None):
    if FCM is None or not tokens:
        return {"configured": FCM is not None, "sentCount": 0, "failureCount": 0}
    sent = failures = 0
    safe_data = {str(k): str(v) for k, v in (data or {}).items() if v is not None}
    for offset in range(0, len(tokens), 500):
        batch = tokens[offset:offset + 500]
        try:
            message = FCM.MulticastMessage(
                tokens=batch,
                notification=FCM.Notification(title=title or "An Tâm Pharma", body=content or ""),
                data=safe_data,
            )
            response = FCM.send_each_for_multicast(message)
            sent += response.success_count
            failures += response.failure_count
        except Exception:
            failures += len(batch)
    return {"configured": True, "sentCount": sent, "failureCount": failures}


def connect():
    db = sqlite3.connect(DB_PATH, timeout=20)
    db.row_factory = sqlite3.Row
    db.execute("PRAGMA foreign_keys = ON")
    return db


def password_hash(value: str) -> str:
    salt = secrets.token_bytes(16)
    digest = hashlib.pbkdf2_hmac("sha256", value.encode(), salt, 180_000).hex()
    return f"pbkdf2_sha256$180000${salt.hex()}${digest}"


def verify_password(value: str, stored: str) -> bool:
    parts = stored.split("$")
    if len(parts) == 4 and parts[0] == "pbkdf2_sha256":
        try:
            iterations = int(parts[1])
            salt = bytes.fromhex(parts[2])
            expected = hashlib.pbkdf2_hmac("sha256", value.encode(), salt, iterations).hex()
            return hmac.compare_digest(expected, parts[3])
        except (ValueError, OverflowError):
            return False
    # Verify the original local seed format once and migrate it after login.
    legacy = hashlib.pbkdf2_hmac("sha256", value.encode(), b"antam-local-v1", 180_000).hex()
    return hmac.compare_digest(legacy, stored)


def seed():
    with connect() as db:
        db.executescript("""
        CREATE TABLE IF NOT EXISTS users(id TEXT PRIMARY KEY, username TEXT UNIQUE, fullName TEXT,
          email TEXT UNIQUE, phone TEXT, passwordHash TEXT, status TEXT DEFAULT 'ACTIVE', roles TEXT,
          createdAt TEXT, avatarUrl TEXT);
        CREATE TABLE IF NOT EXISTS sessions(token TEXT PRIMARY KEY, userId TEXT, createdAt TEXT);
        CREATE TABLE IF NOT EXISTS categories(id TEXT PRIMARY KEY, name TEXT, slug TEXT UNIQUE, description TEXT, isActive INTEGER DEFAULT 1, imageUrl TEXT);
        CREATE TABLE IF NOT EXISTS brands(id TEXT PRIMARY KEY, name TEXT, slug TEXT UNIQUE, description TEXT, isActive INTEGER DEFAULT 1, logoUrl TEXT);
        CREATE TABLE IF NOT EXISTS products(id TEXT PRIMARY KEY, categoryId TEXT, categoryName TEXT,
          brandId TEXT, brandName TEXT, name TEXT, slug TEXT UNIQUE, sku TEXT UNIQUE, shortDescription TEXT,
          description TEXT, ingredients TEXT, usageInstructions TEXT, dosage TEXT, sideEffects TEXT,
          precautions TEXT, storageInstructions TEXT, unit TEXT, price REAL, originalPrice REAL,
          requiresPrescription INTEGER DEFAULT 0, isActive INTEGER DEFAULT 1, isFeatured INTEGER DEFAULT 0,
          thumbnailUrl TEXT, images TEXT DEFAULT '[]', createdAt TEXT, updatedAt TEXT);
        CREATE TABLE IF NOT EXISTS records(kind TEXT, id TEXT, ownerId TEXT, payload TEXT, createdAt TEXT,
          PRIMARY KEY(kind,id));
        CREATE TABLE IF NOT EXISTS device_tokens(id TEXT PRIMARY KEY, userId TEXT, token TEXT UNIQUE, platform TEXT, createdAt TEXT);
        CREATE TABLE IF NOT EXISTS password_otps(userId TEXT PRIMARY KEY, code TEXT, expiresAt TEXT, verified INTEGER DEFAULT 0);
        """)
        brand_columns={r["name"] for r in db.execute("PRAGMA table_info(brands)")}
        if "country" not in brand_columns: db.execute("ALTER TABLE brands ADD COLUMN country TEXT")
        if not db.execute("SELECT 1 FROM users LIMIT 1").fetchone():
            for uid, username, name, email, phone, role in [
                ("u-admin", "ductri", "DucTri", "ductri@antam.local", "0900000001", "ADMIN"),
                ("u-staff", "ngoctien", "NgocTien", "ngoctien@antam.local", "0900000002", "PHARMACIST"),
                ("u-customer", "khachhang", "Khách hàng mẫu", "khachhang@antam.local", "0900000003", "CUSTOMER"),
            ]:
                db.execute("INSERT INTO users VALUES(?,?,?,?,?,?,?,?,?,?)", (uid, username, name, email, phone, password_hash("12345678"), "ACTIVE", json.dumps([role]), NOW(), None))
        if not db.execute("SELECT 1 FROM categories LIMIT 1").fetchone():
            categories = [("cat-pain", "Giảm đau, hạ sốt"), ("cat-vitamins", "Vitamin và khoáng chất"), ("cat-digestive", "Tiêu hóa"), ("cat-skin", "Chăm sóc da")]
            for cid, name in categories:
                db.execute("INSERT INTO categories(id,name,slug,description) VALUES(?,?,?,?)", (cid, name, cid, "Sản phẩm chăm sóc sức khỏe chính hãng"))
        if not db.execute("SELECT 1 FROM brands LIMIT 1").fetchone():
            for bid, name in [("brand-dhg", "DHG Pharma"), ("brand-sanofi", "Sanofi"), ("brand-pfizer", "Pfizer")]:
                db.execute("INSERT INTO brands(id,name,slug,description) VALUES(?,?,?,?)", (bid, name, bid, "Thương hiệu dược phẩm"))
        if not db.execute("SELECT 1 FROM products LIMIT 1").fetchone():
            products = [
                ("p-paracetamol", "cat-pain", "Giảm đau, hạ sốt", "brand-dhg", "DHG Pharma", "Paracetamol 500mg", 18000, "viên", 0, 1),
                ("p-vitc", "cat-vitamins", "Vitamin và khoáng chất", "brand-sanofi", "Sanofi", "Vitamin C 1000mg", 65000, "tuýp", 0, 1),
                ("p-omeprazole", "cat-digestive", "Tiêu hóa", "brand-pfizer", "Pfizer", "Omeprazole 20mg", 42000, "hộp", 1, 0),
                ("p-saline", "cat-skin", "Chăm sóc da", "brand-dhg", "DHG Pharma", "Nước muối sinh lý 0.9%", 12000, "chai", 0, 1),
                ("p-calcium", "cat-vitamins", "Vitamin và khoáng chất", "brand-sanofi", "Sanofi", "Calcium + D3", 89000, "lọ", 0, 0),
                ("p-cough", "cat-pain", "Giảm đau, hạ sốt", "brand-dhg", "DHG Pharma", "Siro ho thảo dược", 53000, "chai", 0, 1),
                ("p-probiotic", "cat-digestive", "Tiêu hóa", "brand-pfizer", "Pfizer", "Men vi sinh hỗ trợ tiêu hóa", 76000, "hộp", 0, 0),
                ("p-sunscreen", "cat-skin", "Chăm sóc da", "brand-sanofi", "Sanofi", "Kem chống nắng SPF 50+", 159000, "tuýp", 0, 1),
            ]
            for pid, cid, cname, bid, bname, name, price, unit, rx, featured in products:
                slug = pid
                db.execute("""INSERT INTO products(id,categoryId,categoryName,brandId,brandName,name,slug,sku,
                  shortDescription,description,unit,price,originalPrice,requiresPrescription,isActive,isFeatured,createdAt,updatedAt)
                  VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""", (pid,cid,cname,bid,bname,name,slug,pid.upper(),"Sản phẩm chăm sóc sức khỏe","Thông tin sử dụng theo hướng dẫn trên bao bì và tư vấn của dược sĩ.",unit,price,price*1.1,rx,1,featured,NOW(),NOW()))
        if not db.execute("SELECT 1 FROM records WHERE kind='vouchers' LIMIT 1").fetchone():
            v={"id":"voucher-chao-mung","code":"CHAOMUNG10","name":"Chào mừng khách hàng mới","description":"Giảm 10% cho đơn hàng từ 100.000đ","discountType":"PERCENTAGE","discountValue":10,"maxDiscountAmount":50000,"minOrderAmount":100000,"usageLimit":500,"usedCount":0,"isActive":True,"createdAt":NOW()}
            db.execute("INSERT INTO records VALUES(?,?,?,?,?)",("vouchers",v["id"],None,json.dumps(v,ensure_ascii=False),NOW()))
        if not db.execute("SELECT 1 FROM records WHERE kind='pharmacies' LIMIT 1").fetchone():
            shops=[{"id":"pharmacy-quan-1","name":"Nhà thuốc An Tâm - Quận 1","address":"12 Nguyễn Huệ","fullAddress":"12 Nguyễn Huệ, Quận 1, TP. Hồ Chí Minh","district":"Quận 1","province":"TP. Hồ Chí Minh","phone":"02838220001","openingHours":"07:00 - 22:00","isActive":True,"latitude":10.7732,"longitude":106.7034},{"id":"pharmacy-binh-thanh","name":"Nhà thuốc An Tâm - Bình Thạnh","address":"88 Xô Viết Nghệ Tĩnh","fullAddress":"88 Xô Viết Nghệ Tĩnh, Bình Thạnh, TP. Hồ Chí Minh","district":"Bình Thạnh","province":"TP. Hồ Chí Minh","phone":"02838220002","openingHours":"07:00 - 21:30","isActive":True,"latitude":10.8011,"longitude":106.7106}]
            for shop in shops: db.execute("INSERT INTO records VALUES(?,?,?,?,?)",("pharmacies",shop["id"],None,json.dumps(shop,ensure_ascii=False),NOW()))
        if not db.execute("SELECT 1 FROM records WHERE kind='inventory' LIMIT 1").fetchone():
            shops=[json.loads(r["payload"]) for r in db.execute("SELECT payload FROM records WHERE kind='pharmacies'")]
            for shop in shops:
                for product in db.execute("SELECT id,name,sku,thumbnailUrl FROM products"):
                    stock={"id":f"inv-{shop['id']}-{product['id']}","pharmacyId":shop["id"],"pharmacyName":shop["name"],"pharmacyAddress":shop["fullAddress"],"productId":product["id"],"productName":product["name"],"productSku":product["sku"],"productImage":product["thumbnailUrl"],"quantity":20,"updatedAt":NOW()}
                    db.execute("INSERT INTO records VALUES(?,?,?,?,?)",("inventory",stock["id"],None,json.dumps(stock,ensure_ascii=False),NOW()))
        extras.migrate(db)


def api(data=None, message="Thành công", status=200):
    return {"status": status, "message": message, "data": data}


def log_activity(db, user, action, entity_name, entity_id=None, description=None):
    if not user:
        return
    payload = {
        "id": "log-" + secrets.token_hex(6),
        "userId": user["id"],
        "userFullName": user.get("fullName"),
        "userEmail": user.get("email"),
        "action": action,
        "actionLabel": action.replace("_", " ").title(),
        "entityName": entity_name,
        "entityId": str(entity_id) if entity_id is not None else None,
        "description": description,
        "ipAddress": None,
        "userAgent": None,
        "createdAt": NOW(),
    }
    db.execute("INSERT INTO records VALUES(?,?,?,?,?)", ("activity_logs", payload["id"], user["id"], json.dumps(payload, ensure_ascii=False), NOW()))


def rowdict(row):
    if row is None: return None
    item = dict(row)
    item.pop("passwordHash", None)
    if "roles" in item and isinstance(item["roles"], str): item["roles"] = json.loads(item["roles"])
    if "images" in item and isinstance(item["images"], str): item["images"] = json.loads(item["images"])
    for key in ("isActive", "isFeatured", "requiresPrescription"):
        if key in item: item[key] = bool(item[key])
    return item


def save_product(db, data, product_id=None, existing=None):
    required = ("name", "sku", "slug", "categoryId", "unit")
    if any(not str(data.get(k, "")).strip() for k in required):
        return None
    category=db.execute("SELECT name FROM categories WHERE id=?",(data["categoryId"],)).fetchone()
    if not category: return None
    brand=db.execute("SELECT name FROM brands WHERE id=?",(data.get("brandId"),)).fetchone() if data.get("brandId") else None
    product_id=product_id or "p-"+secrets.token_hex(6)
    old=existing or {}
    record={"id":product_id,"categoryId":data["categoryId"],"categoryName":category["name"],"brandId":data.get("brandId"),"brandName":brand["name"] if brand else None,"name":data["name"],"slug":data["slug"],"sku":data["sku"],"shortDescription":data.get("shortDescription"),"description":data.get("description"),"ingredients":data.get("ingredients"),"usageInstructions":data.get("usageInstructions"),"dosage":data.get("dosage"),"sideEffects":data.get("sideEffects"),"precautions":data.get("precautions"),"storageInstructions":data.get("storageInstructions"),**{k:data.get(k,old.get(k)) for k in extras.EXTRA_PRODUCT_COLUMNS},"unit":data["unit"],"price":float(data.get("price",old.get("price",0)) or 0),"originalPrice":data.get("originalPrice",old.get("originalPrice")),"requiresPrescription":int(bool(data.get("requiresPrescription",old.get("requiresPrescription",False)))),"isActive":int(bool(data.get("isActive",old.get("isActive",True)))),"isFeatured":int(bool(data.get("isFeatured",old.get("isFeatured",False)))),"thumbnailUrl":data.get("thumbnailUrl",old.get("thumbnailUrl")),"images":json.dumps(data.get("images",old.get("images",[])),ensure_ascii=False),"createdAt":old.get("createdAt",NOW()),"updatedAt":NOW()}
    columns=list(record)
    db.execute(f"INSERT OR REPLACE INTO products({','.join(columns)}) VALUES({','.join('?' for _ in columns)})",tuple(record[k] for k in columns))
    return rowdict(db.execute("SELECT * FROM products WHERE id=?",(product_id,)).fetchone())


class Handler(BaseHTTPRequestHandler):
    server_version = "AnTamLocalAPI/1.0"

    def log_message(self, fmt, *args): print("%s - %s" % (self.address_string(), fmt % args))

    def send_json(self, body, code=200):
        # Commit trước khi trả lời để request kế tiếp của client luôn thấy dữ liệu mới.
        db = getattr(self, "_db", None)
        if db is not None:
            db.commit()
        is_html = isinstance(body, str)
        raw = body.encode() if is_html else json.dumps(body, ensure_ascii=False, default=str).encode()
        self.send_response(code); self.send_header("Content-Type", "text/html; charset=utf-8" if is_html else "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(raw))); self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Authorization, Content-Type")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
        self.end_headers(); self.wfile.write(raw)

    def send_file(self, path):
        content_type=mimetypes.guess_type(path.name)[0] or "application/octet-stream"
        data=path.read_bytes(); self.send_response(200); self.send_header("Content-Type",content_type); self.send_header("Content-Length",str(len(data))); self.send_header("X-Content-Type-Options","nosniff"); self.end_headers(); self.wfile.write(data)

    def do_OPTIONS(self): self.send_json(api())

    def body(self):
        n = int(self.headers.get("Content-Length", 0))
        raw=self.rfile.read(n)
        content_type=self.headers.get("Content-Type","")
        if content_type.lower().startswith("multipart/form-data"):
            if n>20*1024*1024: raise ValueError("Tệp vượt quá giới hạn 20MB")
            message=BytesParser(policy=policy.default).parsebytes((f"Content-Type: {content_type}\r\nMIME-Version: 1.0\r\n\r\n".encode()+raw))
            fields={}; files=[]
            for part in message.iter_parts():
                name=part.get_param("name",header="content-disposition")
                payload=part.get_payload(decode=True) or b""
                filename=part.get_filename()
                if filename: files.append({"field":name,"filename":filename,"contentType":part.get_content_type(),"data":payload})
                else: fields[name]=payload.decode(part.get_content_charset() or "utf-8",errors="replace")
            fields["__files__"]=files; return fields
        return json.loads(raw or b"{}")

    def save_upload(self, file):
        filename=os.path.basename(file["filename"] or "upload"); ext=Path(filename).suffix.lower()
        if ext not in ALLOWED_UPLOAD_EXT:
            # Trình duyệt (Flutter Web) đôi khi gửi tên không có đuôi: suy ra từ content-type hoặc nội dung file.
            ext=extras.sniff_extension(file.get("contentType"), file["data"]) or ext
        if ext not in ALLOWED_UPLOAD_EXT: raise ValueError("Chỉ nhận tệp JPG, PNG, WEBP hoặc PDF")
        if len(file["data"])>15*1024*1024: raise ValueError("Tệp vượt quá giới hạn 15MB")
        safe_name=secrets.token_hex(16)+ext; target=UPLOAD_DIR/safe_name; target.write_bytes(file["data"])
        return {"url":f"http://{self.headers.get('Host','localhost')}/api/v1/files/{safe_name}","fileUrl":f"http://{self.headers.get('Host','localhost')}/api/v1/files/{safe_name}","fileName":safe_name,"originalFileName":filename,"size":len(file["data"]),"contentType":file["contentType"]}

    def user(self, db):
        token = self.headers.get("Authorization", "").removeprefix("Bearer ").strip()
        if not token: return None
        row = db.execute("SELECT u.* FROM users u JOIN sessions s ON s.userId=u.id WHERE s.token=?", (token,)).fetchone()
        return rowdict(row)

    def dispatch(self, method):
        parsed = urlparse(self.path); path = parsed.path.removeprefix("/api/v1").rstrip("/") or "/"
        q = {k:v[-1] for k,v in parse_qs(parsed.query).items()}
        try: data = self.body() if method in ("POST","PUT","PATCH") else {}
        except (ValueError, json.JSONDecodeError) as error: return self.send_json(api(None,str(error),400),400)
        if path.startswith("/files/") and method=="GET":
            filename=path.split("/")[-1]
            if filename!=Path(filename).name: return self.send_json(api(None,"Tệp không tồn tại",404),404)
            target=UPLOAD_DIR/filename
            if not target.is_file(): return self.send_json(api(None,"Tệp không tồn tại",404),404)
            return self.send_file(target)
        with connect() as db:
            self._db = db
            user = self.user(db)
            if path == "/health": return self.send_json(api({"status":"UP","database":"SQLite","file":str(DB_PATH),"version":BUILD_VERSION,"source":str(Path(__file__).resolve()),"momoSandbox":extras.momo.config()["isSandbox"],"bankAccountIsSample":extras.bank_info()["accountNo"]=="0123456789"}))
            if path == "/auth/login" and method == "POST":
                key = str(data.get("username", data.get("email", ""))).strip().lower()
                u = db.execute("SELECT * FROM users WHERE lower(username)=? OR lower(email)=? OR phone=?", (key,key,key)).fetchone()
                if not u or not verify_password(str(data.get("password", "")), u["passwordHash"]) or u["status"] != "ACTIVE":
                    return self.send_json(api(None,"Email/tài khoản hoặc mật khẩu không đúng",401),401)
                token=secrets.token_urlsafe(36); db.execute("INSERT INTO sessions VALUES(?,?,?)",(token,u["id"],NOW()))
                return self.send_json(api({"accessToken":token,"refreshToken":token,"tokenType":"Bearer","expiresIn":86400,"user":rowdict(u)}))
            if path == "/auth/register" and method == "POST":
                email=str(data.get("email","")).strip().lower(); username=str(data.get("username") or email).strip().lower()
                if not email or len(str(data.get("password",""))) < 8: return self.send_json(api(None,"Email hoặc mật khẩu không hợp lệ",400),400)
                if db.execute("SELECT 1 FROM users WHERE email=? OR username=?",(email,username)).fetchone(): return self.send_json(api(None,"Tài khoản đã tồn tại",409),409)
                uid="u-"+secrets.token_hex(6); db.execute("INSERT INTO users VALUES(?,?,?,?,?,?,?,?,?,?)",(uid,username,data.get("fullName",username),email,data.get("phone"),password_hash(data["password"]),"ACTIVE",json.dumps(["CUSTOMER"]),NOW(),None))
                token=secrets.token_urlsafe(36); db.execute("INSERT INTO sessions VALUES(?,?,?)",(token,uid,NOW()))
                return self.send_json(api({"accessToken":token,"refreshToken":token,"tokenType":"Bearer","expiresIn":86400,"user":rowdict(db.execute("SELECT * FROM users WHERE id=?",(uid,)).fetchone())}),201)
            if path == "/auth/logout" and method == "POST":
                db.execute("DELETE FROM sessions WHERE token=?",(self.headers.get("Authorization", "").removeprefix("Bearer "),)); return self.send_json(api())
            if path == "/auth/me" and method == "GET": return self.send_json(api(user) if user else api(None,"Vui lòng đăng nhập",401),200 if user else 401)
            if path == "/auth/forgot-password" and method == "POST":
                key=str(data.get("username","")).strip().lower()
                target=db.execute("SELECT id FROM users WHERE lower(username)=? OR lower(email)=? OR phone=?",(key,key,key)).fetchone()
                if not target: return self.send_json(api(None,"Không tìm thấy tài khoản",404),404)
                db.execute("INSERT OR REPLACE INTO password_otps VALUES(?,?,?,0)",(target["id"],"123456",(datetime.now(timezone.utc)+timedelta(minutes=10)).isoformat()))
                return self.send_json(api({"message":"Mã OTP demo cục bộ: 123456","expiresInMinutes":10}))
            if path == "/auth/verify-forgot-password-otp" and method == "POST":
                key=str(data.get("username","")).strip().lower(); target=db.execute("SELECT id FROM users WHERE lower(username)=? OR lower(email)=? OR phone=?",(key,key,key)).fetchone()
                otp=db.execute("SELECT * FROM password_otps WHERE userId=?",(target["id"],)).fetchone() if target else None
                verified=bool(otp and str(data.get("otpCode",""))==otp["code"] and otp["expiresAt"]>NOW())
                if verified: db.execute("UPDATE password_otps SET verified=1 WHERE userId=?",(target["id"],))
                return self.send_json(api({"verified":verified,"message":"Mã OTP hợp lệ" if verified else "Mã OTP không hợp lệ"}),200 if verified else 400)
            if path == "/auth/reset-password-with-otp" and method == "POST":
                key=str(data.get("username","")).strip().lower(); target=db.execute("SELECT id FROM users WHERE lower(username)=? OR lower(email)=? OR phone=?",(key,key,key)).fetchone()
                otp=db.execute("SELECT * FROM password_otps WHERE userId=?",(target["id"],)).fetchone() if target else None
                new_password=str(data.get("newPassword",""))
                if not otp or not otp["verified"] or data.get("otpCode")!=otp["code"] or otp["expiresAt"]<=NOW(): return self.send_json(api(None,"Hãy xác thực OTP trước",400),400)
                if len(new_password)<8 or new_password!=data.get("confirmPassword"): return self.send_json(api(None,"Mật khẩu không hợp lệ hoặc xác nhận không khớp",400),400)
                db.execute("UPDATE users SET passwordHash=? WHERE id=?",(password_hash(new_password),target["id"]))
                db.execute("DELETE FROM password_otps WHERE userId=?",(target["id"],)); db.execute("DELETE FROM sessions WHERE userId=?",(target["id"],))
                return self.send_json(api({"message":"Đổi mật khẩu thành công"}))
            if path.startswith("/auth/"):
                return self.send_json(api(None,"Không tìm thấy API xác thực",404),404)
            admin_write = method in ("POST", "PUT", "PATCH", "DELETE") and (path.startswith(("/products", "/categories", "/brands", "/pharmacies", "/inventory", "/admin/vouchers", "/vouchers/admin")) or (path.startswith("/vouchers") and path!="/vouchers/apply"))
            privileged_route=path.startswith(("/admin/","/prescriptions/admin","/orders/admin","/pharmacies/admin","/inventory/admin")) or path.endswith("/admin") or admin_write
            is_pharmacist_route=path.startswith("/prescriptions/admin")
            allowed_roles={"ADMIN","PHARMACIST"} if is_pharmacist_route else {"ADMIN"}
            if privileged_route and (not user or not allowed_roles.intersection(user["roles"])):
                return self.send_json(api(None,"Bạn không có quyền quản trị",403),403)
            if extras.handle(self.send_json, db, send_fcm, method, path, q, data, user): return
            if path in ("/categories","/categories/admin"):
                if method == "GET":
                    rows=[rowdict(x) for x in db.execute("SELECT * FROM categories ORDER BY name")]
                    return self.send_json(api(rows))
                if path == "/categories" and method == "POST":
                    cid="cat-"+secrets.token_hex(5); slug=str(data.get("slug","")).strip()
                    if not data.get("name") or not slug: return self.send_json(api(None,"Vui lòng nhập tên và đường dẫn danh mục",400),400)
                    if db.execute("SELECT 1 FROM categories WHERE slug=?",(slug,)).fetchone(): return self.send_json(api(None,"Đường dẫn danh mục đã tồn tại",409),409)
                    db.execute("INSERT INTO categories(id,name,slug,description,isActive,imageUrl) VALUES(?,?,?,?,?,?)",(cid,data["name"],slug,data.get("description"),int(bool(data.get("isActive",True))),data.get("imageUrl")))
                    return self.send_json(api(rowdict(db.execute("SELECT * FROM categories WHERE id=?",(cid,)).fetchone())),201)
            if path.startswith("/categories/") and path != "/categories/admin":
                cid=path.split("/")[-1]; existing=db.execute("SELECT * FROM categories WHERE id=?",(cid,)).fetchone()
                if method == "GET": return self.send_json(api(rowdict(existing)) if existing else api(None,"Không tìm thấy danh mục",404),200 if existing else 404)
                if not existing: return self.send_json(api(None,"Không tìm thấy danh mục",404),404)
                if method == "PUT":
                    slug=str(data.get("slug",existing["slug"])).strip()
                    duplicate=db.execute("SELECT 1 FROM categories WHERE slug=? AND id<>?",(slug,cid)).fetchone()
                    if duplicate: return self.send_json(api(None,"Đường dẫn danh mục đã tồn tại",409),409)
                    db.execute("UPDATE categories SET name=?,slug=?,description=?,isActive=?,imageUrl=? WHERE id=?",(data.get("name",existing["name"]),slug,data.get("description",existing["description"]),int(bool(data.get("isActive",existing["isActive"]))),data.get("imageUrl",existing["imageUrl"]),cid))
                    db.execute("UPDATE products SET categoryName=? WHERE categoryId=?",(data.get("name",existing["name"]),cid))
                    return self.send_json(api(rowdict(db.execute("SELECT * FROM categories WHERE id=?",(cid,)).fetchone())))
                if method == "DELETE":
                    if db.execute("SELECT 1 FROM products WHERE categoryId=? LIMIT 1",(cid,)).fetchone(): return self.send_json(api(None,"Danh mục còn sản phẩm, hãy ẩn thay vì xóa",409),409)
                    db.execute("DELETE FROM categories WHERE id=?",(cid,)); return self.send_json(api(None))
            if path in ("/brands","/brands/admin"):
                if method=="GET":
                    rows=[rowdict(x) for x in db.execute("SELECT * FROM brands ORDER BY name")]
                    return self.send_json(api(rows if path.endswith("/admin") or (user and "ADMIN" in user["roles"]) else [x for x in rows if x["isActive"]]))
                if path=="/brands" and method=="POST":
                    if not data.get("name"): return self.send_json(api(None,"Vui lòng nhập tên thương hiệu",400),400)
                    bid="brand-"+secrets.token_hex(5); db.execute("INSERT INTO brands(id,name,slug,description,isActive,logoUrl,country) VALUES(?,?,?,?,?,?,?)",(bid,data["name"],bid,data.get("description"),int(bool(data.get("isActive",True))),data.get("logoUrl"),data.get("country")))
                    return self.send_json(api(rowdict(db.execute("SELECT * FROM brands WHERE id=?",(bid,)).fetchone())),201)
            if path.startswith("/brands/") and path!="/brands/admin":
                bid=path.split("/")[-1]; brand=db.execute("SELECT * FROM brands WHERE id=?",(bid,)).fetchone()
                if method=="GET": return self.send_json(api(rowdict(brand)) if brand else api(None,"Không tìm thấy thương hiệu",404),200 if brand else 404)
                if not brand: return self.send_json(api(None,"Không tìm thấy thương hiệu",404),404)
                if method=="PUT":
                    values=(data.get("name",brand["name"]),data.get("description",brand["description"]),int(bool(data.get("isActive",brand["isActive"]))),data.get("logoUrl",brand["logoUrl"]),data.get("country",brand["country"]),bid)
                    db.execute("UPDATE brands SET name=?,description=?,isActive=?,logoUrl=?,country=? WHERE id=?",values); db.execute("UPDATE products SET brandName=? WHERE brandId=?",(values[0],bid))
                    return self.send_json(api(rowdict(db.execute("SELECT * FROM brands WHERE id=?",(bid,)).fetchone())))
                if method=="DELETE":
                    if db.execute("SELECT 1 FROM products WHERE brandId=? LIMIT 1",(bid,)).fetchone(): return self.send_json(api(None,"Thương hiệu đang có sản phẩm, hãy ẩn thay vì xóa",409),409)
                    db.execute("DELETE FROM brands WHERE id=?",(bid,)); return self.send_json(api(None))
            if path == "/products" or path.startswith("/products/"):
                if path == "/products" and method == "GET":
                    rows=[rowdict(x) for x in db.execute("SELECT * FROM products ORDER BY name" if user and "ADMIN" in user["roles"] else "SELECT * FROM products WHERE isActive=1 ORDER BY name")]
                    rows=extras.filter_products(db,rows,q)
                    page=int(q.get("page",0)); size=int(q.get("size",10)); total=len(rows); selected=extras.decorate(db,rows[page*size:(page+1)*size],user)
                    return self.send_json(api({"content":selected,"page":page,"size":size,"totalElements":total,"totalPages":max(1,(total+size-1)//size),"last":(page+1)*size>=total,"first":page==0,"numberOfElements":len(selected),"empty":not selected}))
                if path == "/products" and method == "POST":
                    product=save_product(db,data)
                    if product is None: return self.send_json(api(None,"Thiếu tên, mã, danh mục hoặc đơn vị sản phẩm",400),400)
                    return self.send_json(api(product),201)
                parts=path.strip("/").split("/")
                if len(parts)==3 and parts[1]=="slug" and method=="GET":
                    row=db.execute("SELECT * FROM products WHERE slug=? AND isActive=1",(parts[2],)).fetchone()
                    return self.send_json(api(rowdict(row)) if row else api(None,"Không tìm thấy sản phẩm",404),200 if row else 404)
                if len(parts)>=3 and parts[2]=="images":
                    product=rowdict(db.execute("SELECT * FROM products WHERE id=?",(parts[1],)).fetchone())
                    if not product: return self.send_json(api(None,"Không tìm thấy sản phẩm",404),404)
                    images=list(product.get("images",[]))
                    if len(parts)==3 and method=="POST":
                        files=[f for f in data.get("__files__",[]) if f.get("field")=="files"]
                        if not files: return self.send_json(api(None,"Vui lòng chọn ảnh sản phẩm",400),400)
                        try:
                            for file in files:
                                uploaded=self.save_upload(file); images.append({"id":"pi-"+secrets.token_hex(4),"imageUrl":uploaded["fileUrl"],"sortOrder":len(images)})
                        except ValueError as error: return self.send_json(api(None,str(error),400),400)
                        db.execute("UPDATE products SET images=?,thumbnailUrl=COALESCE(thumbnailUrl,?),updatedAt=? WHERE id=?",(json.dumps(images,ensure_ascii=False),images[0]["imageUrl"],NOW(),parts[1])); return self.send_json(api(None))
                    image_id=parts[3] if len(parts)>3 else None
                    image=next((x for x in images if x.get("id")==image_id),None)
                    if len(parts)==5 and parts[4]=="thumbnail" and method=="PUT" and image:
                        db.execute("UPDATE products SET thumbnailUrl=?,updatedAt=? WHERE id=?",(image["imageUrl"],NOW(),parts[1])); return self.send_json(api(None))
                    if len(parts)==4 and method=="DELETE" and image:
                        images=[x for x in images if x.get("id")!=image_id]; thumbnail=images[0]["imageUrl"] if images and product.get("thumbnailUrl")==image["imageUrl"] else product.get("thumbnailUrl")
                        db.execute("UPDATE products SET images=?,thumbnailUrl=?,updatedAt=? WHERE id=?",(json.dumps(images,ensure_ascii=False),thumbnail,NOW(),parts[1])); return self.send_json(api(None))
                    return self.send_json(api(None,"Không tìm thấy ảnh sản phẩm",404),404)
                key=parts[-1]
                row=db.execute("SELECT * FROM products WHERE id=? OR slug=?",(key,key)).fetchone()
                if len(parts)==2 and method == "GET": return self.send_json(api(rowdict(row)) if row else api(None,"Không tìm thấy sản phẩm",404),200 if row else 404)
                if len(parts)==2 and method in ("PUT","PATCH") and row:
                    product=save_product(db,data,row["id"],rowdict(row)); return self.send_json(api(product))
                if len(parts)==2 and method == "DELETE" and row:
                    db.execute("UPDATE products SET isActive=0,updatedAt=? WHERE id=?",(NOW(),row["id"])); return self.send_json(api(None))
                return self.send_json(api(None,"Không tìm thấy sản phẩm",404),404)
            if path.startswith("/users/addresses"):
                if not user: return self.send_json(api(None,"Vui lòng đăng nhập",401),401)
                parts=path.strip("/").split("/"); address_id=parts[2] if len(parts)>2 else None; action=parts[3] if len(parts)>3 else None
                if method=="GET" and not address_id:
                    return self.send_json(api([json.loads(r["payload"]) for r in db.execute("SELECT payload FROM records WHERE kind='addresses' AND ownerId=? ORDER BY createdAt",(user["id"],))]))
                if method=="POST" and not address_id:
                    aid="addr-"+secrets.token_hex(5); is_default=bool(data.get("isDefault",False)) or not db.execute("SELECT 1 FROM records WHERE kind='addresses' AND ownerId=? LIMIT 1",(user["id"],)).fetchone(); payload={**data,"id":aid,"isDefault":is_default,"createdAt":NOW(),"updatedAt":NOW()}
                    payload["fullAddress"]=", ".join(str(payload.get(k,"")) for k in ("detailAddress","ward","district","province") if payload.get(k))
                    if payload["isDefault"]: db.execute("UPDATE records SET payload=json_set(payload,'$.isDefault',false) WHERE kind='addresses' AND ownerId=?",(user["id"],))
                    db.execute("INSERT INTO records VALUES(?,?,?,?,?)",("addresses",aid,user["id"],json.dumps(payload,ensure_ascii=False),NOW()))
                    return self.send_json(api(payload),201)
                if not address_id: return self.send_json(api(None,"Không tìm thấy địa chỉ",404),404)
                row=db.execute("SELECT payload FROM records WHERE kind='addresses' AND id=? AND ownerId=?",(address_id,user["id"])).fetchone()
                if not row: return self.send_json(api(None,"Không tìm thấy địa chỉ",404),404)
                payload=json.loads(row["payload"])
                if method=="GET": return self.send_json(api(payload))
                if method=="PUT" and action=="default":
                    db.execute("UPDATE records SET payload=json_set(payload,'$.isDefault',false) WHERE kind='addresses' AND ownerId=?",(user["id"],)); payload["isDefault"]=True
                elif method=="PUT":
                    payload.update(data); payload["updatedAt"]=NOW(); payload["fullAddress"]=", ".join(str(payload.get(k,"")) for k in ("detailAddress","ward","district","province") if payload.get(k))
                    if payload.get("isDefault"): db.execute("UPDATE records SET payload=json_set(payload,'$.isDefault',false) WHERE kind='addresses' AND ownerId=?",(user["id"],))
                elif method=="DELETE":
                    db.execute("DELETE FROM records WHERE kind='addresses' AND id=? AND ownerId=?",(address_id,user["id"])); return self.send_json(api(None))
                else: return self.send_json(api(None,"Thao tác địa chỉ không hợp lệ",405),405)
                db.execute("UPDATE records SET payload=? WHERE kind='addresses' AND id=?",(json.dumps(payload,ensure_ascii=False),address_id)); return self.send_json(api(payload))
            if path in ("/users/profile", "/users/avatar"):
                if not user: return self.send_json(api(None,"Vui lòng đăng nhập",401),401)
                if method == "GET": return self.send_json(api(user))
                if method == "PUT":
                    allowed = {"fullName", "phone", "gender", "dateOfBirth", "avatarUrl"}
                    changes={k:v for k,v in data.items() if k in allowed}
                    if path.endswith("/avatar") and "avatarUrl" in data: changes={"avatarUrl":data["avatarUrl"]}
                    if changes:
                        cols=", ".join(f"{k}=?" for k in changes)
                        db.execute(f"UPDATE users SET {cols} WHERE id=?", (*changes.values(),user["id"]))
                    return self.send_json(api(rowdict(db.execute("SELECT * FROM users WHERE id=?",(user["id"],)).fetchone())))
            if path == "/cart" and method == "GET":
                if not user: return self.send_json(api(None,"Vui lòng đăng nhập",401),401)
                entries=[json.loads(r["payload"]) for r in db.execute("SELECT payload FROM records WHERE kind='cart' AND ownerId=? ORDER BY createdAt",(user["id"],))]
                total=sum(float(x.get("unitPrice",x.get("price",0)) or 0)*int(x.get("quantity",1) or 1) for x in entries)
                return self.send_json(api({"id":"cart-"+user["id"],"status":"ACTIVE","items":entries,"totalItems":sum(int(x.get("quantity",1) or 1) for x in entries),"totalAmount":total,"hasPrescriptionProduct":any(x.get("requiresPrescription",False) for x in entries)}))
            if path.startswith("/reviews"):
                if path=="/reviews" and method=="POST":
                    if not user: return self.send_json(api(None,"Vui lòng đăng nhập",401),401)
                    product=rowdict(db.execute("SELECT * FROM products WHERE id=?",(data.get("productId"),)).fetchone())
                    rating=int(data.get("rating",0) or 0)
                    if not product or rating<1 or rating>5: return self.send_json(api(None,"Sản phẩm hoặc số sao đánh giá không hợp lệ",400),400)
                    rid="review-"+secrets.token_hex(6); review={"id":rid,"userId":user["id"],"userFullName":user.get("fullName"),"userAvatarUrl":user.get("avatarUrl"),"productId":product["id"],"productName":product["name"],"orderId":data.get("orderId"),"rating":rating,"comment":data.get("comment"),"isVisible":True,"createdAt":NOW(),"updatedAt":NOW()}
                    db.execute("INSERT INTO records VALUES(?,?,?,?,?)",("reviews",rid,user["id"],json.dumps(review,ensure_ascii=False),NOW())); return self.send_json(api(review),201)
                if path.startswith("/reviews/products/") and method=="GET":
                    pid=path.split("/")[-1]; reviews=[json.loads(r["payload"]) for r in db.execute("SELECT payload FROM records WHERE kind='reviews' ORDER BY createdAt DESC") if json.loads(r["payload"]).get("productId")==pid and json.loads(r["payload"]).get("isVisible",True)]
                elif path=="/reviews/my-reviews" and method=="GET":
                    if not user: return self.send_json(api(None,"Vui lòng đăng nhập",401),401)
                    reviews=[json.loads(r["payload"]) for r in db.execute("SELECT payload FROM records WHERE kind='reviews' AND ownerId=? ORDER BY createdAt DESC",(user["id"],))]
                else: return self.send_json(api(None,"Không tìm thấy API đánh giá",404),404)
                page=int(q.get("page",0)); size=int(q.get("size",10)); total=len(reviews); content=reviews[page*size:(page+1)*size]
                return self.send_json(api({"content":content,"page":page,"size":size,"totalElements":total,"totalPages":max(1,(total+size-1)//size),"last":(page+1)*size>=total,"first":page==0,"numberOfElements":len(content),"empty":not content}))
            if path.startswith("/prescriptions"):
                if path=="/prescriptions/upload" and method=="POST":
                    if not user: return self.send_json(api(None,"Vui lòng đăng nhập",401),401)
                    files=[f for f in data.get("__files__",[]) if f.get("field")=="files"]
                    if not files: return self.send_json(api(None,"Vui lòng tải ảnh đơn thuốc",400),400)
                    try: images=[{"id":"rxi-"+secrets.token_hex(4),"imageUrl":self.save_upload(file)["fileUrl"],"sortOrder":i} for i,file in enumerate(files)]
                    except ValueError as error: return self.send_json(api(None,str(error),400),400)
                    rid="rx-"+secrets.token_hex(6); prescription={"id":rid,"userId":user["id"],"customerName":user.get("fullName"),"patientName":data.get("patientName",user.get("fullName","")),"patientPhone":data.get("patientPhone",user.get("phone")),"note":data.get("note"),"status":"PENDING","statusLabel":"Chờ dược sĩ duyệt","pharmacistNote":None,"images":images,"createdAt":NOW(),"updatedAt":NOW()}
                    db.execute("INSERT INTO records VALUES(?,?,?,?,?)",("prescriptions",rid,user["id"],json.dumps(prescription,ensure_ascii=False),NOW())); return self.send_json(api(prescription),201)
                if path=="/prescriptions" and method=="POST":
                    if not user: return self.send_json(api(None,"Vui lòng đăng nhập",401),401)
                    rid="rx-"+secrets.token_hex(6); images=[{"id":"rxi-"+secrets.token_hex(4),"imageUrl":url,"sortOrder":i} for i,url in enumerate(data.get("imageUrls",[]))]
                    prescription={"id":rid,"userId":user["id"],"customerName":user.get("fullName"),"patientName":data.get("patientName",user.get("fullName","")),"patientPhone":data.get("patientPhone",user.get("phone")),"note":data.get("note"),"status":"PENDING","statusLabel":"Chờ dược sĩ duyệt","pharmacistNote":None,"images":images,"createdAt":NOW(),"updatedAt":NOW()}
                    db.execute("INSERT INTO records VALUES(?,?,?,?,?)",("prescriptions",rid,user["id"],json.dumps(prescription,ensure_ascii=False),NOW())); return self.send_json(api(prescription),201)
                if path=="/prescriptions/my-prescriptions" and method=="GET":
                    if not user: return self.send_json(api(None,"Vui lòng đăng nhập",401),401)
                    prescriptions=[json.loads(r["payload"]) for r in db.execute("SELECT payload FROM records WHERE kind='prescriptions' AND ownerId=? ORDER BY createdAt DESC",(user["id"],))]
                elif path=="/prescriptions/admin" and method=="GET":
                    prescriptions=[json.loads(r["payload"]) for r in db.execute("SELECT payload FROM records WHERE kind='prescriptions' ORDER BY createdAt DESC")]
                elif path.startswith("/prescriptions/admin/") and method=="PUT":
                    parts=path.strip("/").split("/"); rid=parts[2]; row=db.execute("SELECT payload FROM records WHERE kind='prescriptions' AND id=?",(rid,)).fetchone()
                    if not row: return self.send_json(api(None,"Không tìm thấy đơn thuốc",404),404)
                    prescription=json.loads(row["payload"]); prescription["status"]=data.get("status",prescription["status"]); prescription["statusLabel"]={"APPROVED":"Đã duyệt","REJECTED":"Từ chối","PENDING":"Chờ dược sĩ duyệt"}.get(prescription["status"],prescription["status"]); prescription["pharmacistId"]=user["id"]; prescription["pharmacistName"]=user.get("fullName"); prescription["pharmacistNote"]=data.get("pharmacistNote"); prescription["reviewedAt"]=NOW(); prescription["updatedAt"]=NOW()
                    if data.get("suggestedProductIds") is not None:
                        prescription["suggestedProducts"]=[{"id":r["id"],"name":r["name"],"price":r["price"],"unit":r["unit"],"thumbnailUrl":r["thumbnailUrl"]} for r in (db.execute("SELECT id,name,price,unit,thumbnailUrl FROM products WHERE id=?",(pid,)).fetchone() for pid in data["suggestedProductIds"]) if r]
                    db.execute("UPDATE records SET payload=? WHERE kind='prescriptions' AND id=?",(json.dumps(prescription,ensure_ascii=False),rid))
                    extras.notify(db,send_fcm,prescription["userId"],"Đơn thuốc đã được xử lý",prescription["statusLabel"]+(": "+prescription["pharmacistNote"] if prescription.get("pharmacistNote") else ""),"PRESCRIPTION",rid)
                    return self.send_json(api(prescription))
                elif path.startswith("/prescriptions/") and method=="GET":
                    rid=path.split("/")[-1]; row=db.execute("SELECT ownerId,payload FROM records WHERE kind='prescriptions' AND id=?",(rid,)).fetchone()
                    if not row or (not user or row["ownerId"]!=user["id"] and not {"ADMIN","PHARMACIST"}.intersection(user["roles"])): return self.send_json(api(None,"Không tìm thấy đơn thuốc",404),404)
                    return self.send_json(api(json.loads(row["payload"])))
                else: return self.send_json(api(None,"Không tìm thấy API đơn thuốc",404),404)
                status_filter=q.get("status")
                if status_filter: prescriptions=[x for x in prescriptions if x.get("status")==status_filter]
                page=int(q.get("page",0)); size=int(q.get("size",10)); total=len(prescriptions); content=prescriptions[page*size:(page+1)*size]
                return self.send_json(api({"content":content,"page":page,"size":size,"totalElements":total,"totalPages":max(1,(total+size-1)//size),"last":(page+1)*size>=total,"first":page==0,"numberOfElements":len(content),"empty":not content}))
            if path.startswith("/cart/items"):
                if not user: return self.send_json(api(None,"Vui lòng đăng nhập",401),401)
                item_id=path.split("/")[-1] if path.count("/") >= 3 else None
                if method == "POST":
                    pid=str(data.get("productId", "")); product=rowdict(db.execute("SELECT * FROM products WHERE id=?",(pid,)).fetchone())
                    if not product: return self.send_json(api(None,"Không tìm thấy sản phẩm",404),404)
                    quantity=max(1,int(data.get("quantity",1) or 1)); rid="ci-"+secrets.token_hex(6)
                    payload={"id":rid,"productId":pid,"productName":product["name"],"productSlug":product["slug"],"productImage":product.get("thumbnailUrl"),"unit":product["unit"],"unitPrice":product["price"],"quantity":quantity,"totalPrice":product["price"]*quantity,"requiresPrescription":product["requiresPrescription"],"isActive":True}
                    db.execute("INSERT INTO records VALUES(?,?,?,?,?)",("cart",rid,user["id"],json.dumps(payload,ensure_ascii=False),NOW()))
                    return self.send_json(api(payload),201)
                if method in ("PUT","PATCH") and item_id:
                    row=db.execute("SELECT payload FROM records WHERE kind='cart' AND id=? AND ownerId=?",(item_id,user["id"])).fetchone()
                    if not row: return self.send_json(api(None,"Không tìm thấy sản phẩm trong giỏ",404),404)
                    payload=json.loads(row["payload"]); payload["quantity"]=max(1,int(data.get("quantity",payload["quantity"]) or 1)); payload["totalPrice"]=payload["unitPrice"]*payload["quantity"]
                    db.execute("UPDATE records SET payload=? WHERE kind='cart' AND id=?",(json.dumps(payload,ensure_ascii=False),item_id)); return self.send_json(api(payload))
                if method == "DELETE":
                    if item_id and item_id != "items": db.execute("DELETE FROM records WHERE kind='cart' AND id=? AND ownerId=?",(item_id,user["id"]))
                    else: db.execute("DELETE FROM records WHERE kind='cart' AND ownerId=?",(user["id"],))
                    return self.send_json(api(None))
            if path == "/admin/activity-logs" and method == "GET":
                logs=[json.loads(r["payload"]) for r in db.execute("SELECT payload FROM records WHERE kind='activity_logs' ORDER BY createdAt DESC")]
                for key in ("action", "entityName", "userId"):
                    if q.get(key): logs=[x for x in logs if str(x.get(key, "")).lower()==q[key].lower()]
                if q.get("keyword"):
                    term=q["keyword"].lower(); logs=[x for x in logs if term in " ".join(str(x.get(k) or "") for k in ("userFullName","userEmail","action","entityName","entityId","description")).lower()]
                for key, op in (("fromDate", "ge"), ("toDate", "le")):
                    if q.get(key): logs=[x for x in logs if (x.get("createdAt", "") >= q[key] if op=="ge" else x.get("createdAt", "") <= q[key])]
                page=max(0,int(q.get("page",0))); size=max(1,min(100,int(q.get("size",20)))); total=len(logs); content=logs[page*size:(page+1)*size]
                return self.send_json(api({"content":content,"page":page,"size":size,"totalElements":total,"totalPages":max(1,(total+size-1)//size),"last":(page+1)*size>=total,"first":page==0,"numberOfElements":len(content),"empty":not content}))
            if path == "/admin/dashboard/overview":
                orders=[json.loads(r["payload"]) for r in db.execute("SELECT payload FROM records WHERE kind='orders'")]; rx=[json.loads(r["payload"]) for r in db.execute("SELECT payload FROM records WHERE kind='prescriptions'")]
                return self.send_json(api({"totalUsers":db.execute("SELECT count(*) FROM users").fetchone()[0],"totalProducts":db.execute("SELECT count(*) FROM products").fetchone()[0],"totalOrders":len(orders),"totalPendingOrders":sum(x.get("orderStatus")=="PENDING" for x in orders),"totalDeliveredOrders":sum(x.get("orderStatus") in extras.DONE_STATUSES for x in orders),"totalPrescriptions":len(rx),"totalPendingPrescriptions":sum(x.get("status")=="PENDING" for x in rx),"totalPharmacies":db.execute("SELECT count(*) FROM records WHERE kind='pharmacies'").fetchone()[0],"totalReviews":db.execute("SELECT count(*) FROM records WHERE kind='reviews'").fetchone()[0],"totalRevenue":sum(float(x.get("finalAmount",0) or 0) for x in orders if x.get("orderStatus")=="COMPLETED")}))
            if path == "/admin/dashboard/order-status":
                orders=[json.loads(r["payload"]) for r in db.execute("SELECT payload FROM records WHERE kind='orders'")]; labels={"PENDING":"Chờ xác nhận","CONFIRMED":"Đã xác nhận","PREPARING":"Đang chuẩn bị","PROCESSING":"Đang xử lý","SHIPPING":"Đang giao","DELIVERED":"Đã giao","COMPLETED":"Hoàn tất","CANCELLED":"Đã hủy"}
                return self.send_json(api([{"status":key,"statusLabel":label,"count":sum(x.get("orderStatus")==key for x in orders)} for key,label in labels.items()]))
            if path == "/admin/dashboard/revenue/last-7-days":
                by_day={}
                for r in db.execute("SELECT payload FROM records WHERE kind='orders'"):
                    order=json.loads(r["payload"]); date=str(order.get("createdAt",""))[:10]
                    if order.get("orderStatus") in extras.DONE_STATUSES:
                        d=by_day.setdefault(date,{"revenue":0,"orderCount":0}); d["revenue"]+=float(order.get("finalAmount",0) or 0); d["orderCount"]+=1
                today=datetime.now(timezone.utc).date(); result=[]
                for offset in range(6,-1,-1):
                    day=today-timedelta(days=offset); label=day.strftime("%d/%m"); record=by_day.get(day.isoformat(),{"revenue":0,"orderCount":0}); result.append({"label":label,**record})
                return self.send_json(api(result))
            if path.startswith(("/admin/vouchers", "/vouchers")):
                admin_route=path.startswith("/admin/vouchers") or path=="/vouchers/admin"
                all_vouchers=[json.loads(r["payload"]) for r in db.execute("SELECT payload FROM records WHERE kind='vouchers' ORDER BY createdAt DESC")]
                all_vouchers=[v for v in all_vouchers if not v.get("ownerUserId") or (user and (v["ownerUserId"]==user["id"] or "ADMIN" in user["roles"]))]
                if path == "/vouchers/apply" and method == "POST":
                    code=str(data.get("code","")).strip().upper(); amount=float(data.get("orderAmount",0) or 0)
                    voucher=next((v for v in all_vouchers if v["code"].upper()==code and v.get("isActive",True)),None)
                    if not voucher: return self.send_json(api(None,"Mã giảm giá không hợp lệ",404),404)
                    if amount<float(voucher.get("minOrderAmount",0)): return self.send_json(api(None,"Đơn hàng chưa đạt giá trị tối thiểu",400),400)
                    discount=amount*float(voucher["discountValue"])/100 if voucher["discountType"]=="PERCENTAGE" else float(voucher["discountValue"])
                    if voucher.get("maxDiscountAmount") is not None: discount=min(discount,float(voucher["maxDiscountAmount"]))
                    discount=min(amount,discount)
                    return self.send_json(api({"voucherId":voucher["id"],"code":voucher["code"],"name":voucher["name"],"orderAmount":amount,"discountAmount":discount,"finalAmount":amount-discount,"message":"Áp dụng mã giảm giá thành công"}))
                if method == "GET" and path in ("/vouchers", "/vouchers/admin", "/admin/vouchers"):
                    return self.send_json(api(all_vouchers if admin_route else [v for v in all_vouchers if v.get("isActive",True)]))
                if len(path.strip("/").split("/"))==2 and method=="GET":
                    vid=path.split("/")[-1]; v=next((x for x in all_vouchers if x["id"]==vid),None)
                    return self.send_json(api(v) if v else api(None,"Không tìm thấy voucher",404),200 if v else 404)
                if method in ("POST","PUT"):
                    vid=path.split("/")[-1] if method=="PUT" else "voucher-"+secrets.token_hex(5)
                    v={**data,"id":vid,"code":str(data.get("code","")).strip().upper(),"usedCount":int(data.get("usedCount",0) or 0),"createdAt":data.get("createdAt",NOW()),"updatedAt":NOW()}
                    if not v["code"] or not v.get("name"): return self.send_json(api(None,"Nhập mã và tên voucher",400),400)
                    if any(x["id"]!=vid and x["code"].upper()==v["code"] for x in all_vouchers): return self.send_json(api(None,"Mã voucher đã tồn tại",409),409)
                    db.execute("INSERT OR REPLACE INTO records VALUES(?,?,?,?,?)",("vouchers",vid,None,json.dumps(v,ensure_ascii=False),NOW()))
                    return self.send_json(api(v),201 if method=="POST" else 200)
                if method=="DELETE":
                    vid=path.split("/")[-1]; db.execute("DELETE FROM records WHERE kind='vouchers' AND id=?",(vid,)); return self.send_json(api(None))
            if path == "/admin/users" and method == "GET": return self.send_json(api([rowdict(r) for r in db.execute("SELECT * FROM users ORDER BY createdAt DESC")]))
            if path.startswith("/admin/users/"):
                parts=path.strip("/").split("/"); uid=parts[2]; action=parts[3] if len(parts)>3 else ""
                target=db.execute("SELECT * FROM users WHERE id=?",(uid,)).fetchone()
                if not target: return self.send_json(api(None,"Không tìm thấy người dùng",404),404)
                if method == "GET" and not action: return self.send_json(api(rowdict(target)))
                if action in ("block","unlock") and method in ("PUT","PATCH"):
                    db.execute("UPDATE users SET status=? WHERE id=?",("BLOCKED" if action=="block" else "ACTIVE",uid))
                elif action == "status" and method in ("PUT","PATCH"):
                    db.execute("UPDATE users SET status=? WHERE id=?",(data.get("status","ACTIVE"),uid))
                elif action == "roles" and method == "POST":
                    roles=json.loads(target["roles"]); role=str(data.get("roleName","")).upper()
                    if role and role not in roles: roles.append(role)
                    db.execute("UPDATE users SET roles=? WHERE id=?",(json.dumps(roles),uid))
                elif action == "roles" and method == "DELETE":
                    role=parts[4].upper() if len(parts)>4 else ""; roles=[r for r in json.loads(target["roles"]) if r.upper()!=role]
                    db.execute("UPDATE users SET roles=? WHERE id=?",(json.dumps(roles),uid))
                elif action == "reset-password" and method in ("POST","PUT"):
                    new_password=str(data.get("newPassword",data.get("password","12345678")))
                    db.execute("UPDATE users SET passwordHash=? WHERE id=?",(password_hash(new_password),uid))
                elif not action and method in ("PUT","PATCH"):
                    allowed={"fullName","email","phone","status"}; changes={k:v for k,v in data.items() if k in allowed}
                    if changes: db.execute("UPDATE users SET "+", ".join(k+"=?" for k in changes)+" WHERE id=?",(*changes.values(),uid))
                else: return self.send_json(api(None,"API quản trị người dùng không hỗ trợ thao tác này",405),405)
                log_activity(db, user, "USER_"+(action or "UPDATE").upper(), "USER", uid, "Cập nhật tài khoản người dùng")
                return self.send_json(api(rowdict(db.execute("SELECT * FROM users WHERE id=?",(uid,)).fetchone())))
            if path == "/admin/notifications/send" and method == "POST":
                recipients=[r["id"] for r in db.execute("SELECT id FROM users WHERE status='ACTIVE' AND roles LIKE '%CUSTOMER%' ")] if data.get("sendToAllCustomers") else [str(data.get("userId", ""))]
                sent=0
                for uid in recipients:
                    if not uid: continue
                    notification={"id":"nt-"+secrets.token_hex(6),"title":data.get("title",""),"content":data.get("content",""),"type":data.get("type","GENERAL"),"referenceId":data.get("referenceId"),"isRead":False,"createdAt":NOW()}
                    db.execute("INSERT INTO records VALUES(?,?,?,?,?)",("notifications",notification["id"],uid,json.dumps(notification,ensure_ascii=False),NOW())); sent+=1
                recipient_ids=[uid for uid in recipients if uid]
                tokens=[row["token"] for row in db.execute("SELECT token FROM device_tokens WHERE userId IN ("+",".join("?" for _ in recipient_ids)+")",recipient_ids)] if recipient_ids else []
                push=send_fcm(tokens,data.get("title",""),data.get("content",""),{"type":data.get("type","GENERAL"),"referenceId":data.get("referenceId")})
                message="Đã lưu thông báo trong ứng dụng"
                if push["configured"]:
                    message+=f"; push FCM thành công {push['sentCount']}, lỗi {push['failureCount']}"
                log_activity(db, user, "NOTIFICATION_SEND", "NOTIFICATION", None, f"Đã lưu thông báo cho {sent} tài khoản; FCM {push['sentCount']} thành công")
                return self.send_json(api({"sentCount":sent,"pushSentCount":push["sentCount"],"pushFailureCount":push["failureCount"],"pushConfigured":push["configured"],"message":message}),201)
            if path == "/notifications/unread-count":
                if not user: return self.send_json(api(None,"Vui lòng đăng nhập",401),401)
                count=sum(not json.loads(r["payload"]).get("isRead",False) for r in db.execute("SELECT payload FROM records WHERE kind='notifications' AND ownerId=?",(user["id"],)))
                return self.send_json(api(count))
            if path == "/notifications" and method == "GET":
                if not user: return self.send_json(api(None,"Vui lòng đăng nhập",401),401)
                return self.send_json(api([json.loads(r["payload"]) for r in db.execute("SELECT payload FROM records WHERE kind='notifications' AND ownerId=? ORDER BY createdAt DESC",(user["id"],))]))
            if path.startswith("/notifications/") and user:
                parts=path.strip("/").split("/"); action=parts[-1]; nid=parts[-2] if len(parts)>2 else ""
                rows=list(db.execute("SELECT id,payload FROM records WHERE kind='notifications' AND ownerId=?",(user["id"],)))
                for row in rows:
                    payload=json.loads(row["payload"])
                    if action=="read-all" or row["id"]==nid and action=="read":
                        payload["isRead"]=True; db.execute("UPDATE records SET payload=? WHERE kind='notifications' AND id=?",(json.dumps(payload,ensure_ascii=False),row["id"]))
                return self.send_json(api(None))
            if path.startswith("/device-tokens"):
                if not user: return self.send_json(api(None,"Vui lòng đăng nhập",401),401)
                if path=="/device-tokens" and method=="POST":
                    tok=str(data.get("token",data.get("deviceToken",""))).strip()
                    if not tok: return self.send_json(api(None,"Token thiết bị không hợp lệ",400),400)
                    tid="dt-"+secrets.token_hex(5); db.execute("INSERT OR REPLACE INTO device_tokens VALUES(?,?,?,?,?)",(tid,user["id"],tok,data.get("platform","unknown"),NOW()))
                    return self.send_json(api({"id":tid,"token":tok,"platform":data.get("platform","unknown"),"active":True,"createdAt":NOW()}),201)
                if path=="/device-tokens" and method=="GET": return self.send_json(api([dict(r) for r in db.execute("SELECT id,token,platform,createdAt FROM device_tokens WHERE userId=?",(user["id"],))]))
                if method=="DELETE": db.execute("DELETE FROM device_tokens WHERE id=? AND userId=?",(path.split("/")[-1],user["id"])); return self.send_json(api(None))
            if path == "/pharmacies" and method == "GET":
                return self.send_json(api([json.loads(r["payload"]) for r in db.execute("SELECT payload FROM records WHERE kind='pharmacies' ORDER BY createdAt")]))
            if path=="/pharmacies/admin":
                if method=="GET": return self.send_json(api([json.loads(r["payload"]) for r in db.execute("SELECT payload FROM records WHERE kind='pharmacies' ORDER BY createdAt")]))
                if method=="POST":
                    pid="pharmacy-"+secrets.token_hex(5); shop={**data,"id":pid,"isActive":bool(data.get("isActive",True)),"createdAt":NOW(),"updatedAt":NOW()}; shop["fullAddress"]=data.get("fullAddress") or ", ".join(str(shop.get(k,"")) for k in ("address","district","province") if shop.get(k)); db.execute("INSERT INTO records VALUES(?,?,?,?,?)",("pharmacies",pid,None,json.dumps(shop,ensure_ascii=False),NOW())); return self.send_json(api(shop),201)
            if path.startswith("/pharmacies/") and path!="/pharmacies/admin":
                pid=path.split("/")[-1]; row=db.execute("SELECT payload FROM records WHERE kind='pharmacies' AND id=?",(pid,)).fetchone()
                if not row: return self.send_json(api(None,"Không tìm thấy nhà thuốc",404),404)
                shop=json.loads(row["payload"])
                if method=="GET": return self.send_json(api(shop))
                if method=="PUT":
                    shop.update(data); shop["updatedAt"]=NOW(); shop["fullAddress"]=data.get("fullAddress") or ", ".join(str(shop.get(k,"")) for k in ("address","district","province") if shop.get(k)); db.execute("UPDATE records SET payload=? WHERE kind='pharmacies' AND id=?",(json.dumps(shop,ensure_ascii=False),pid)); return self.send_json(api(shop))
                if method=="DELETE": shop["isActive"]=False; shop["updatedAt"]=NOW(); db.execute("UPDATE records SET payload=? WHERE kind='pharmacies' AND id=?",(json.dumps(shop,ensure_ascii=False),pid)); return self.send_json(api(None))
                return self.send_json(api(None,"Thao tác nhà thuốc không hợp lệ",405),405)
            if path=="/inventory/admin":
                stocks=[json.loads(r["payload"]) for r in db.execute("SELECT payload FROM records WHERE kind='inventory' ORDER BY createdAt")]
                for field in ("pharmacyId","productId"):
                    if q.get(field): stocks=[x for x in stocks if x.get(field)==q[field]]
                if q.get("keyword"):
                    term=q["keyword"].lower(); stocks=[x for x in stocks if term in (str(x.get("productName",""))+" "+str(x.get("productSku",""))).lower()]
                if method=="GET": return self.send_json(api(stocks))
                if method=="POST":
                    pharmacy=db.execute("SELECT payload FROM records WHERE kind='pharmacies' AND id=?",(data.get("pharmacyId"),)).fetchone()
                    product=rowdict(db.execute("SELECT * FROM products WHERE id=?",(data.get("productId"),)).fetchone())
                    if not pharmacy or not product: return self.send_json(api(None,"Nhà thuốc hoặc sản phẩm không tồn tại",404),404)
                    shop=json.loads(pharmacy["payload"]); stock=next((x for x in stocks if x["pharmacyId"]==shop["id"] and x["productId"]==product["id"]),None)
                    if stock is None: stock={"id":"inv-"+secrets.token_hex(6),"pharmacyId":shop["id"],"pharmacyName":shop["name"],"pharmacyAddress":shop["fullAddress"],"productId":product["id"],"productName":product["name"],"productSku":product["sku"],"productImage":product.get("thumbnailUrl"),"quantity":0}
                    stock["quantity"]=max(0,int(data.get("quantity",0) or 0)); stock["updatedAt"]=NOW()
                    db.execute("INSERT OR REPLACE INTO records VALUES(?,?,?,?,?)",("inventory",stock["id"],None,json.dumps(stock,ensure_ascii=False),NOW())); return self.send_json(api(stock),201)
            if path.startswith("/inventory/admin/"):
                parts=path.strip("/").split("/"); stock_id=parts[2]; action=parts[3] if len(parts)>3 else ""
                row=db.execute("SELECT payload FROM records WHERE kind='inventory' AND id=?",(stock_id,)).fetchone()
                if not row: return self.send_json(api(None,"Không tìm thấy tồn kho",404),404)
                stock=json.loads(row["payload"])
                if action=="quantity" and method=="PUT":
                    stock["quantity"]=max(0,int(data.get("quantity",0) or 0)); stock["updatedAt"]=NOW(); db.execute("UPDATE records SET payload=?,createdAt=? WHERE kind='inventory' AND id=?",(json.dumps(stock,ensure_ascii=False),NOW(),stock_id)); return self.send_json(api(stock))
                if method=="DELETE": db.execute("DELETE FROM records WHERE kind='inventory' AND id=?",(stock_id,)); return self.send_json(api(None))
            if path.startswith("/inventory/products/") and method=="GET":
                pid=path.split("/")[-1]; stocks=[json.loads(r["payload"]) for r in db.execute("SELECT payload FROM records WHERE kind='inventory'") if json.loads(r["payload"]).get("productId")==pid]
                return self.send_json(api(stocks))
            if path.startswith("/inventory/pharmacies/") and method=="GET":
                pid=path.split("/")[-1]; stocks=[json.loads(r["payload"]) for r in db.execute("SELECT payload FROM records WHERE kind='inventory'") if json.loads(r["payload"]).get("pharmacyId")==pid]
                page=int(q.get("page",0)); size=int(q.get("size",10)); total=len(stocks); content=stocks[page*size:(page+1)*size]
                return self.send_json(api({"content":content,"page":page,"size":size,"totalElements":total,"totalPages":max(1,(total+size-1)//size),"last":(page+1)*size>=total,"first":page==0,"numberOfElements":len(content),"empty":not content}))
            if path=="/files/upload" and method=="POST":
                if not user: return self.send_json(api(None,"Vui lòng đăng nhập",401),401)
                files=[f for f in data.get("__files__",[]) if f.get("field")=="file"]
                if not files: return self.send_json(api(None,"Vui lòng chọn tệp cần tải lên",400),400)
                try: return self.send_json(api(self.save_upload(files[0]),201),201)
                except ValueError as error: return self.send_json(api(None,str(error),400),400)
            if path.startswith("/payments/vnpay"):
                return self.send_json(api(None,"VNPay chưa được cấu hình merchant credentials; chọn thanh toán COD hoặc cấu hình sandbox VNPay",503),503)
            if path.startswith("/payments"):
                if not user: return self.send_json(api(None,"Vui lòng đăng nhập",401),401)
                if path=="/payments" and method=="POST":
                    order_row=db.execute("SELECT ownerId,payload FROM records WHERE kind='orders' AND id=?",(data.get("orderId"),)).fetchone()
                    if not order_row or order_row["ownerId"]!=user["id"]: return self.send_json(api(None,"Không tìm thấy đơn hàng",404),404)
                    order=json.loads(order_row["payload"]); pid="pay-"+secrets.token_hex(5); payment={"id":pid,"orderId":order["id"],"orderCode":order["orderCode"],"paymentMethod":data.get("paymentMethod",order["paymentMethod"]),"amount":order["finalAmount"],"transactionCode":None,"paymentStatus":"PENDING","paymentStatusLabel":"Chờ thanh toán","createdAt":NOW()}
                    db.execute("INSERT INTO records VALUES(?,?,?,?,?)",("payments",pid,user["id"],json.dumps(payment,ensure_ascii=False),NOW())); return self.send_json(api(payment),201)
                if path=="/payments/my-payments" and method=="GET": return self.send_json(api([json.loads(r["payload"]) for r in db.execute("SELECT payload FROM records WHERE kind='payments' AND ownerId=? ORDER BY createdAt DESC",(user["id"],))]))
                parts=path.strip("/").split("/")
                if len(parts)==3 and parts[1]=="order" and method=="GET":
                    order_row=db.execute("SELECT ownerId FROM records WHERE kind='orders' AND id=?",(parts[2],)).fetchone()
                    if not order_row or order_row["ownerId"]!=user["id"]: return self.send_json(api(None,"Không tìm thấy giao dịch",404),404)
                    payment_row=db.execute("SELECT payload FROM records WHERE kind='payments' AND json_extract(payload,'$.orderId')=? ORDER BY createdAt DESC LIMIT 1",(parts[2],)).fetchone()
                    return self.send_json(api(json.loads(payment_row["payload"])) if payment_row else api(None,"Chưa có giao dịch thanh toán",404),200 if payment_row else 404)
                if len(parts)==3 and parts[-1]=="status" and method=="PUT":
                    row=db.execute("SELECT ownerId,payload FROM records WHERE kind='payments' AND id=?",(parts[1],)).fetchone()
                    if not row or row["ownerId"]!=user["id"] and "ADMIN" not in user["roles"]: return self.send_json(api(None,"Không tìm thấy giao dịch",404),404)
                    if data.get("paymentStatus") in ("PAID","SUCCESS","REFUNDED") and "ADMIN" not in user["roles"]: return self.send_json(api(None,"Chỉ quản trị viên hoặc cổng thanh toán mới được xác nhận thanh toán",403),403)
                    payment=json.loads(row["payload"]); payment["paymentStatus"]=data.get("paymentStatus",payment["paymentStatus"]); payment["paymentStatusLabel"]={"PAID":"Đã thanh toán","FAILED":"Thanh toán thất bại","REFUNDED":"Đã hoàn tiền"}.get(payment["paymentStatus"],"Chờ thanh toán"); payment["transactionCode"]=data.get("transactionCode"); payment["paidAt"]=NOW() if payment["paymentStatus"]=="PAID" else None; db.execute("UPDATE records SET payload=? WHERE kind='payments' AND id=?",(json.dumps(payment,ensure_ascii=False),payment["id"]))
                    order_row=db.execute("SELECT payload FROM records WHERE kind='orders' AND id=?",(payment["orderId"],)).fetchone()
                    if order_row:
                        order=json.loads(order_row["payload"]); order["paymentStatus"]=payment["paymentStatus"]; order["updatedAt"]=NOW(); db.execute("UPDATE records SET payload=? WHERE kind='orders' AND id=?",(json.dumps(order,ensure_ascii=False),order["id"]))
                    return self.send_json(api(payment))
                if len(parts)==2 and method=="GET":
                    row=db.execute("SELECT ownerId,payload FROM records WHERE kind='payments' AND id=?",(parts[1],)).fetchone()
                    if row and (row["ownerId"]==user["id"] or "ADMIN" in user["roles"]): return self.send_json(api(json.loads(row["payload"])))
                return self.send_json(api(None,"Không tìm thấy giao dịch",404),404)
            if path.startswith("/orders"):
                if path=="/orders" and method=="POST":
                    if not user: return self.send_json(api(None,"Vui lòng đăng nhập",401),401)
                    cart_rows=list(db.execute("SELECT id,payload FROM records WHERE kind='cart' AND ownerId=?",(user["id"],)))
                    if not cart_rows: return self.send_json(api(None,"Giỏ hàng đang trống",400),400)
                    address_row=db.execute("SELECT payload FROM records WHERE kind='addresses' AND id=? AND ownerId=?",(data.get("addressId"),user["id"])).fetchone()
                    if not address_row: return self.send_json(api(None,"Vui lòng chọn địa chỉ giao hàng",400),400)
                    pharmacy_id=data.get("pharmacyId") or "pharmacy-quan-1"; shop_row=db.execute("SELECT payload FROM records WHERE kind='pharmacies' AND id=? AND json_extract(payload,'$.isActive')=true",(pharmacy_id,)).fetchone()
                    if not shop_row: return self.send_json(api(None,"Nhà thuốc không tồn tại hoặc đã ngừng hoạt động",404),404)
                    pharmacy=json.loads(shop_row["payload"]); address=json.loads(address_row["payload"]); items=[]; stock_updates=[]; total=0.0
                    for cart_row in cart_rows:
                        cart_item=json.loads(cart_row["payload"]); product=rowdict(db.execute("SELECT * FROM products WHERE id=? AND isActive=1",(cart_item["productId"],)).fetchone())
                        if not product: return self.send_json(api(None,"Một sản phẩm trong giỏ đã ngừng kinh doanh",409),409)
                        stock_row=db.execute("SELECT id,payload FROM records WHERE kind='inventory' AND json_extract(payload,'$.pharmacyId')=? AND json_extract(payload,'$.productId')=?",(pharmacy_id,product["id"])).fetchone()
                        stock=json.loads(stock_row["payload"]) if stock_row else None
                        if not stock or int(stock.get("quantity",0))<int(cart_item["quantity"]): return self.send_json(api(None,"Nhà thuốc không đủ tồn kho cho sản phẩm "+product["name"],409),409)
                        stock_updates.append((stock_row["id"],stock,int(cart_item["quantity"])))
                        if product["requiresPrescription"]:
                            rx=db.execute("SELECT 1 FROM records WHERE kind='prescriptions' AND ownerId=? AND id=? AND json_extract(payload,'$.status')='APPROVED'",(user["id"],data.get("prescriptionId"))).fetchone()
                            if not rx: return self.send_json(api(None,"Sản phẩm này cần đơn thuốc đã được dược sĩ duyệt",400),400)
                        line_total=product["price"]*int(cart_item["quantity"]); total+=line_total
                        items.append({"id":"oi-"+secrets.token_hex(5),"productId":product["id"],"productName":product["name"],"productImage":product.get("thumbnailUrl"),"unitPrice":product["price"],"quantity":int(cart_item["quantity"]),"totalPrice":line_total})
                    discount=0.0; voucher=None
                    if data.get("voucherId"):
                        voucher_row=db.execute("SELECT payload FROM records WHERE kind='vouchers' AND id=?",(data["voucherId"],)).fetchone(); voucher=json.loads(voucher_row["payload"]) if voucher_row else None
                        if not voucher or not voucher.get("isActive",True) or total<float(voucher.get("minOrderAmount",0)): return self.send_json(api(None,"Voucher không hợp lệ với đơn hàng",400),400)
                        if voucher.get("usageLimit") is not None and int(voucher.get("usedCount",0))>=int(voucher["usageLimit"]): return self.send_json(api(None,"Voucher đã hết lượt sử dụng",409),409)
                        discount=total*float(voucher["discountValue"])/100 if voucher["discountType"]=="PERCENTAGE" else float(voucher["discountValue"]); discount=min(total,discount,float(voucher.get("maxDiscountAmount") or total)); voucher["usedCount"]=int(voucher.get("usedCount",0))+1
                    rid="ord-"+secrets.token_hex(5); order_code="AT"+rid[-8:].upper(); status_history=[{"id":"osh-"+secrets.token_hex(4),"status":"PENDING","statusLabel":"Chờ xác nhận","note":"Đơn hàng được tạo","changedByName":user.get("fullName"),"createdAt":NOW()}]
                    payload={"id":rid,"orderCode":order_code,"userId":user["id"],"customerName":user.get("fullName"),"addressId":address["id"],"receiverName":address["receiverName"],"receiverPhone":address["receiverPhone"],"shippingAddress":address["fullAddress"],"pharmacyId":pharmacy_id,"pharmacyName":pharmacy["name"],"prescriptionId":data.get("prescriptionId"),"voucherId":voucher["id"] if voucher else None,"voucherCode":voucher["code"] if voucher else None,"totalAmount":total,"discountAmount":discount,"shippingFee":0,"finalAmount":total-discount,"paymentMethod":data.get("paymentMethod","COD"),"paymentStatus":"PENDING","orderStatus":"PENDING","orderStatusLabel":"Chờ xác nhận","note":data.get("note"),"items":items,"statusHistories":status_history,"createdAt":NOW(),"updatedAt":NOW()}
                    db.execute("INSERT INTO records VALUES(?,?,?,?,?)",("orders",rid,user["id"],json.dumps(payload,ensure_ascii=False),NOW()))
                    for stock_id,stock,quantity in stock_updates:
                        stock["quantity"]-=quantity; stock["updatedAt"]=NOW(); db.execute("UPDATE records SET payload=?,createdAt=? WHERE kind='inventory' AND id=?",(json.dumps(stock,ensure_ascii=False),NOW(),stock_id))
                    if voucher: db.execute("UPDATE records SET payload=? WHERE kind='vouchers' AND id=?",(json.dumps(voucher,ensure_ascii=False),voucher["id"]))
                    db.execute("DELETE FROM records WHERE kind='cart' AND ownerId=?",(user["id"],))
                    return self.send_json(api(payload),201)
                if path in ("/orders/my-orders","/orders/admin") and method=="GET":
                    if path=="/orders/my-orders" and not user: return self.send_json(api(None,"Vui lòng đăng nhập",401),401)
                    owner_clause="" if path=="/orders/admin" else " AND ownerId=?"; params=() if not owner_clause else (user["id"],)
                    orders=[json.loads(r["payload"]) for r in db.execute("SELECT payload FROM records WHERE kind='orders'"+owner_clause+" ORDER BY createdAt DESC",params)]
                    if q.get("status"): orders=[x for x in orders if x.get("orderStatus")==q["status"]]
                    page=int(q.get("page",0)); size=int(q.get("size",10)); total=len(orders); content=orders[page*size:(page+1)*size]
                    return self.send_json(api({"content":content,"page":page,"size":size,"totalElements":total,"totalPages":max(1,(total+size-1)//size),"last":(page+1)*size>=total,"first":page==0,"numberOfElements":len(content),"empty":not content}))
                if path.startswith("/orders/admin/") and path.endswith("/status") and method=="PUT":
                    oid=path.strip("/").split("/")[2]; row=db.execute("SELECT payload FROM records WHERE kind='orders' AND id=?",(oid,)).fetchone()
                    if not row: return self.send_json(api(None,"Không tìm thấy đơn hàng",404),404)
                    order=json.loads(row["payload"]); new_status=str(data.get("status",order["orderStatus"])); order["orderStatus"]=new_status; order["orderStatusLabel"]={"CONFIRMED":"Đã xác nhận","PREPARING":"Đang chuẩn bị","PROCESSING":"Đang xử lý","SHIPPING":"Đang giao","DELIVERED":"Đã giao","COMPLETED":"Hoàn tất","CANCELLED":"Đã hủy"}.get(new_status,new_status); order["updatedAt"]=NOW(); order["statusHistories"].append({"id":"osh-"+secrets.token_hex(4),"status":new_status,"statusLabel":order["orderStatusLabel"],"note":data.get("note"),"changedByName":user.get("fullName"),"createdAt":NOW()})
                    if new_status in extras.DONE_STATUSES: extras.award_order_points(db,send_fcm,order); order["paymentStatus"]="PAID" if order.get("paymentMethod")=="COD" else order.get("paymentStatus")
                    db.execute("UPDATE records SET payload=? WHERE kind='orders' AND id=?",(json.dumps(order,ensure_ascii=False),oid))
                    extras.notify(db,send_fcm,order["userId"],"Cập nhật đơn hàng",f"Đơn {order['orderCode']}: {order['orderStatusLabel']}","ORDER",oid); log_activity(db,user,"ORDER_STATUS_UPDATE","ORDER",oid,"Cập nhật trạng thái đơn hàng thành "+new_status); return self.send_json(api(order))
                parts=path.strip("/").split("/"); oid=parts[1] if len(parts)>1 else ""; row=db.execute("SELECT ownerId,payload FROM records WHERE kind='orders' AND id=?",(oid,)).fetchone()
                if not row: return self.send_json(api(None,"Không tìm thấy đơn hàng",404),404)
                order=json.loads(row["payload"])
                if not user or (row["ownerId"]!=user["id"] and "ADMIN" not in user["roles"]): return self.send_json(api(None,"Không tìm thấy đơn hàng",404),404)
                if len(parts)==3 and parts[2]=="status-history" and method=="GET": return self.send_json(api(order.get("statusHistories",[])))
                if len(parts)==3 and parts[2]=="cancel" and method=="PUT":
                    if order["orderStatus"] not in ("PENDING","CONFIRMED"): return self.send_json(api(None,"Đơn hàng đã được xử lý, không thể hủy",409),409)
                    if order.get("paymentStatus")=="PAID": return self.send_json(api(None,"Đơn hàng đã thanh toán, vui lòng liên hệ hỗ trợ để hoàn tiền",409),409)
                    order["orderStatus"]="CANCELLED"; order["orderStatusLabel"]="Đã hủy"; order["cancelReason"]=data.get("reason"); order["updatedAt"]=NOW(); order["statusHistories"].append({"id":"osh-"+secrets.token_hex(4),"status":"CANCELLED","statusLabel":"Đã hủy","note":data.get("reason"),"changedByName":user.get("fullName"),"createdAt":NOW()})
                    for item in order.get("items",[]):
                        stock_row=db.execute("SELECT id,payload FROM records WHERE kind='inventory' AND json_extract(payload,'$.pharmacyId')=? AND json_extract(payload,'$.productId')=?",(order["pharmacyId"],item.get("productId"))).fetchone()
                        if stock_row:
                            stock=json.loads(stock_row["payload"]); stock["quantity"]=int(stock.get("quantity",0))+int(item.get("quantity",0)); stock["updatedAt"]=NOW(); db.execute("UPDATE records SET payload=?,createdAt=? WHERE kind='inventory' AND id=?",(json.dumps(stock,ensure_ascii=False),NOW(),stock_row["id"]))
                    db.execute("UPDATE records SET payload=? WHERE kind='orders' AND id=?",(json.dumps(order,ensure_ascii=False),oid)); return self.send_json(api(order))
                if len(parts)==2 and method=="GET": return self.send_json(api(order))
                return self.send_json(api(None,"Không tìm thấy API đơn hàng",404),404)
            # Store non-catalog feature payloads locally. This keeps order/cart/review/prescription
            # records durable while integrations such as VNPay and email remain explicit opt-ins.
            parts=path.strip("/").split("/"); kind=parts[0] if parts else "records"
            if method == "GET":
                if not user: return self.send_json(api(None,"Vui lòng đăng nhập",401),401)
                rs=db.execute("SELECT * FROM records WHERE kind=? AND (ownerId=? OR ?='admin') ORDER BY createdAt DESC",(kind,user["id"],"admin" if "ADMIN" in user["roles"] else ""))
                return self.send_json(api([json.loads(r["payload"]) for r in rs]))
            if method == "POST":
                if not user: return self.send_json(api(None,"Vui lòng đăng nhập",401),401)
                rid=str(data.get("id") or kind[:3]+"-"+secrets.token_hex(6)); payload={**data,"id":rid,"createdAt":data.get("createdAt",NOW())}
                db.execute("INSERT OR REPLACE INTO records VALUES(?,?,?,?,?)",(kind,rid,user["id"],json.dumps(payload,ensure_ascii=False),NOW()))
                return self.send_json(api(payload),201)
            return self.send_json(api(None,"API chưa hỗ trợ thao tác này",501),501)

    def do_GET(self): self.dispatch("GET")
    def do_POST(self): self.dispatch("POST")
    def do_PUT(self): self.dispatch("PUT")
    def do_PATCH(self): self.dispatch("PATCH")
    def do_DELETE(self): self.dispatch("DELETE")


if __name__ == "__main__":
    seed(); configure_firebase(); extras.start_scheduler(connect, lambda: send_fcm); host=os.environ.get("HOST","0.0.0.0"); port=int(os.environ.get("PORT","8082"))
    try:
        server=ThreadingHTTPServer((host,port),Handler)
    except OSError as error:
        print(f"\n[LỖI] Không mở được cổng {port}: {error}\n"
              f"Rất có thể backend CŨ vẫn đang chạy ở cổng này nên bản mới không khởi động được.\n"
              f"Hãy tắt tiến trình cũ (PowerShell): Get-NetTCPConnection -LocalPort {port} | "
              f"ForEach-Object {{ Stop-Process -Id $_.OwningProcess -Force }}  rồi chạy lại.\n", flush=True)
        raise SystemExit(1)
    bank=extras.bank_info()
    print(f"An Tam Pharma API {BUILD_VERSION} running at http://{host}:{port}/api/v1 (SQLite: {DB_PATH})")
    print(f"Mã nguồn đang chạy: {Path(__file__).resolve()}")
    print(f"Ngân hàng nhận tiền: {bank['bankName']} (BIN {bank['bankId']}) - TK ...{bank['accountNo'][-4:]} - {bank['accountName']}"
          + ("  [ĐANG DÙNG TÀI KHOẢN MẪU - hãy sửa trong run.ps1]" if bank["accountNo"]=="0123456789" else ""), flush=True)
    server.serve_forever()
