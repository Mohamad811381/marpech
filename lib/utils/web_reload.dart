// رابط عمومی: روی وب از web_reload_web.dart استفاده می‌کند،
// روی بقیه پلتفرم‌ها از web_reload_stub.dart.
export 'web_reload_stub.dart'
    if (dart.library.html) 'web_reload_web.dart';