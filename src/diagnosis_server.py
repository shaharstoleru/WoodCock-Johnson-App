from flask import Flask, request, jsonify, render_template_string
from flask_cors import CORS
import json
from datetime import datetime

app = Flask(__name__)
CORS(app)  # מאפשר CORS לכל הדומיינים


@app.route('/')
def home():
    return """
    <h1>שרת מערכת האבחון הפסיכו-חינוכית</h1>
    <p>השרת פועל בהצלחה!</p>
    <p>נתוני האבחון יתקבלו ב: <strong>/submit_diagnosis</strong></p>
    """


@app.route('/submit_diagnosis', methods=['POST'])
def submit_diagnosis():
    try:
        # קבלת הנתונים מהבקשה
        data = request.get_json()

        if not data:
            return jsonify({'error': 'לא נשלחו נתונים'}), 400

        # הדפסת כל הנתונים על המסך
        print("=" * 80)
        print("נתוני אבחון חדשים התקבלו!")
        print("זמן קבלה:", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
        print("=" * 80)

        # פרטי התלמיד
        print("\n🧒 פרטי התלמיד:")
        print("-" * 40)
        student_fields = [
            ('studentName', 'שם התלמיד'),
            ('studentId', 'ת.ז התלמיד'),
            ('birthDate', 'תאריך לידה'),
            ('testDate', 'תאריך בדיקה'),
            ('grade', 'כיתה'),
            ('school', 'בית ספר'),
            ('parentName', 'שם הורה'),
            ('parentPhone', 'טלפון הורה'),
            ('teacherName', 'שם מורה'),
            ('counselorName', 'שם יועצת'),
            ('referralReason', 'סיבת הפניה'),
            ('medicalHistory', 'היסטוריה רפואית'),
            ('developmentalHistory', 'היסטוריה התפתחותית')
        ]

        for field, label in student_fields:
            value = data.get(field, 'לא צוין')
            print(f"{label}: {value}")

        # מבחן וודקוק ג'ונסון
        print("\n📊 מבחן וודקוק ג'ונסון:")
        print("-" * 40)
        wj_fields = [
            ('wj_cooperation', 'שיתוף פעולה'),
            ('wj_motivation', 'בעיות מוטיבציה'),
            ('wj_attention', 'רמת קשב'),
            ('wj_persistence', 'רמת התמדה'),
            ('wj_task_approach', 'גישה למשימה'),
            ('wj_activity_level', 'רמת פעילות'),
            ('wj_working_style', 'סגנון ביצועי'),
            ('wj_other', 'אחר'),
            ('wj_additional_notes', 'הערות נוספות')
        ]

        for field, label in wj_fields:
            value = data.get(field, 'לא צוין')
            if value and value != 'לא צוין':
                print(f"{label}: {value}")

        # מבחן בנדר
        print("\n🎨 מבחן בנדר:")
        print("-" * 40)
        bender_fields = [
            ('bender_raw', 'ציון גולמי'),
            ('bender_standard', 'ציון סטנדרטי'),
            ('bender_percentile', 'אחוזון'),
            ('bender_age_equivalent', 'גיל שקילות'),
            ('bender_development', 'אינדקס התפתחות'),
            ('bender_observations', 'תצפיות והערות')
        ]

        for field, label in bender_fields:
            value = data.get(field, 'לא צוין')
            if value and value != 'לא צוין':
                print(f"{label}: {value}")

        # מבחן קונרס
        print("\n⚡ מבחן קונרס:")
        print("-" * 40)
        conners_teacher = data.get('conners_teacher_score', 'לא צוין')
        conners_parent = data.get('conners_parent_score', 'לא צוין')
        print(f"ציון T מורים: {conners_teacher}")
        print(f"ציון T הורים: {conners_parent}")

        # מבחן א-ת
        print("\n📚 מבחן א-ת:")
        print("-" * 40)
        alef_tav_fields = [
            ('alef_tav_letters', 'זיהוי אותיות'),
            ('alef_tav_words', 'קריאת מילים'),
            ('alef_tav_comprehension', 'הבנת הנקרא'),
            ('alef_tav_writing', 'כתיבה'),
            ('alef_tav_phonological', 'תודעה פונולוגית'),
            ('alef_tav_processing', 'מהירות עיבוד'),
            ('alef_tav_summary', 'סיכום מבחן א-ת')
        ]

        for field, label in alef_tav_fields:
            value = data.get(field, 'לא צוין')
            if value and value != 'לא צוין':
                print(f"{label}: {value}")

        # בריף מורים/הורים
        print("\n🧠 בריף:")
        print("-" * 40)
        brief_teacher = data.get('brief_teacher_score', 'לא צוין')
        brief_parent = data.get('brief_parent_score', 'לא צוין')
        print(f"ציון מורים: {brief_teacher}")
        print(f"ציון הורים: {brief_parent}")

        # מבחנים רגשיים
        print("\n💭 מבחנים רגשיים:")
        print("-" * 40)
        anxiety_score = data.get('anxiety_score', 'לא צוין')
        sdq_score = data.get('sdq_score', 'לא צוין')
        emotional_obs = data.get('emotional_observations', 'לא צוין')
        print(f"ציון חרדה: {anxiety_score}")
        print(f"ציון SDQ: {sdq_score}")
        print(f"תצפיות רגשיות: {emotional_obs}")

        # סיכומים
        print("\n📝 סיכומים והמלצות:")
        print("-" * 40)
        summary_fields = [
            ('general_summary', 'סיכום כללי'),
            ('general_recommendations', 'המלצות כלליות'),
            ('school_recommendations', 'המלצות לבית ספר'),
            ('parent_recommendations', 'המלצות להורים')
        ]

        for field, label in summary_fields:
            value = data.get(field, 'לא צוין')
            if value and value != 'לא צוין':
                print(f"{label}: {value}")

        # תשובות שאלונים (אם קיימות)
        print("\n📋 תשובות שאלונים:")
        print("-" * 40)

        # ספירת תשובות קונרס מורים
        teacher_responses = []
        parent_responses = []
        brief_teacher_responses = []
        brief_parent_responses = []
        anxiety_responses = []
        sdq_responses = []

        for key, value in data.items():
            if key.startswith('teacher_q') and value:
                teacher_responses.append(f"{key}: {value}")
            elif key.startswith('parent_q') and value:
                parent_responses.append(f"{key}: {value}")
            elif key.startswith('brief_teacher_q') and value:
                brief_teacher_responses.append(f"{key}: {value}")
            elif key.startswith('brief_parent_q') and value:
                brief_parent_responses.append(f"{key}: {value}")
            elif key.startswith('anxiety_q') and value:
                anxiety_responses.append(f"{key}: {value}")
            elif key.startswith('sdq_q') and value:
                sdq_responses.append(f"{key}: {value}")

        if teacher_responses:
            print("תשובות קונרס מורים:")
            for response in teacher_responses:
                print(f"  {response}")

        if parent_responses:
            print("תשובות קונרס הורים:")
            for response in parent_responses:
                print(f"  {response}")

        if brief_teacher_responses:
            print("תשובות בריף מורים:")
            for response in brief_teacher_responses[:5]:  # מציג רק 5 ראשונות
                print(f"  {response}")
            if len(brief_teacher_responses) > 5:
                print(f"  ... ועוד {len(brief_teacher_responses) - 5} תשובות")

        if brief_parent_responses:
            print("תשובות בריף הורים:")
            for response in brief_parent_responses[:5]:
                print(f"  {response}")
            if len(brief_parent_responses) > 5:
                print(f"  ... ועוד {len(brief_parent_responses) - 5} תשובות")

        if anxiety_responses:
            print("תשובות מבחן חרדה:")
            for response in anxiety_responses:
                print(f"  {response}")

        if sdq_responses:
            print("תשובות SDQ:")
            for response in sdq_responses:
                print(f"  {response}")

        print("\n" + "=" * 80)
        print("סיום הדפסת נתוני האבחון")
        print("=" * 80)

        # החזרת תגובה למשתמש
        return jsonify({
            'success': True,
            'message': 'הנתונים נשלחו בהצלחה!',
            'timestamp': datetime.now().isoformat(),
            'student_name': data.get('studentName', 'לא צוין')
        })

    except Exception as e:
        print(f"שגיאה בעיבוד הנתונים: {str(e)}")
        return jsonify({'error': f'שגיאה בעיבוד הנתונים: {str(e)}'}), 500


@app.route('/test', methods=['GET'])
def test():
    return jsonify({'message': 'השרת פועל תקין!'})


if __name__ == '__main__':
    print("מתחיל שרת מערכת האבחון הפסיכו-חינוכית...")
    print("השרת זמין בכתובת: http://localhost:5000")
    print("נתיב לשליחת נתונים: http://localhost:5000/submit_diagnosis")
    app.run(debug=True, host='0.0.0.0', port=5000)