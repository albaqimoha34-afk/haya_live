#!/bin/bash
echo "========================================"
echo "  اعداد مشروع هيا لايف تلقائيا"
echo "========================================"
echo ""
echo "[1/2] توليد ملفات المنصات (android, ios, web)..."
flutter create .
echo ""
echo "[2/2] تنزيل الحزم المطلوبة..."
flutter pub get
echo ""
echo "========================================"
echo "  تم الانتهاء! افتح المشروع الآن في"
echo "  Xcode أو Android Studio واضغط Run"
echo "========================================"
echo ""
echo "تذكير: لازم تفتح lib/services/email_service.dart"
echo "وتضيف بريدك الإلكتروني وكلمة مرور التطبيق (App Password)"
echo "قبل تجربة نسيت كلمة المرور"
