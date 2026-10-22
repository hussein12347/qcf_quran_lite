import re
import os

def sync_newlines(input_filename, output_filename):
    base_path = os.path.dirname(os.path.abspath(__file__))
    input_path = os.path.join(base_path, input_filename)
    output_path = os.path.join(base_path, output_filename)

    print(f"--- بدء مطابقة الأسطر الجديدة في {input_filename} ---")
    
    with open(input_path, 'r', encoding='utf-8') as f_in, \
         open(output_path, 'w', encoding='utf-8') as f_out:
        
        current_aya_text = ""
        
        for line in f_in:
            # 1. التقاط نص الآية العادي لمعرفة أماكن الـ \n
            text_match = re.search(r'"aya_text":\s*"(.*?)"', line)
            if text_match:
                current_aya_text = text_match.group(1)
                f_out.write(line)
                continue

            # 2. معالجة qcfData بناءً على aya_text
            qcf_match = re.search(r'("qcfData":\s*")(.*?)(")', line)
            if qcf_match and current_aya_text:
                prefix = qcf_match.group(1)
                # تنظيف الـ qcfData من أي أسطر قديمة تماماً
                raw_qcf = qcf_match.group(2).replace("\\n", "").strip()
                suffix = qcf_match.group(3)

                # منطق المطابقة:
                # تقسيم النص العادي لمقاطع بناءً على \n
                text_segments = current_aya_text.split("\\n")
                # إزالة المقاطع الفارغة في النهاية
                text_segments = [s for s in text_segments if s.strip()]
                
                # حساب عدد الكلمات الكلي في النص العادي مقابل عدد الرموز في QCF
                words_in_text = current_aya_text.replace("\\n", " ").split()
                qcf_symbols = list(raw_qcf) # كل رمز يعتبر كلمة

                if len(text_segments) <= 1:
                    # إذا لم يوجد سطر جديد في النص الأصلي، نضع الـ QCF كما هو منظفاً
                    new_qcf_value = raw_qcf
                else:
                    # توزيع الرموز بناءً على عدد الكلمات في كل سطر أصلي
                    new_segments = []
                    symbol_index = 0
                    for seg in text_segments:
                        seg_word_count = len(seg.split())
                        # نأخذ عدد رموز من QCF يساوي عدد كلمات السطر الحالي
                        chunk = qcf_symbols[symbol_index : symbol_index + seg_word_count]
                        new_segments.append("".join(chunk))
                        symbol_index += seg_word_count
                    
                    # دمج المقاطع بـ \n
                    new_qcf_value = "\\n".join(new_segments)

                f_out.write(f'    "qcfData": "{new_qcf_value}",\n')
                current_aya_text = "" # تصفير للآية التالية
            else:
                f_out.write(line)

    print(f"✅ تمت مطابقة التنسيق بنجاح في: {output_filename}")

# التشغيل
sync_newlines('quran_combined.dart', 'quran_synced.dart')