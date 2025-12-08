import requests
import mysql.connector
from datetime import date, timedelta
import time

# --- KONFIGURASI ---
API_KEY = '9X8CXBAJ8XQUL5SQMDRZTH9GB'
LOCATION = 'Semarang'  # Ganti dengan kotamu
START_DATE = '2020-01-01' # Mulai dari tahun berapa
END_DATE = '2024-01-01'   # Sampai kapan
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'passwd': '',
    'database': 'weather_app_bd'
}
# -------------------

def fetch_and_save():
    # URL API Visual Crossing untuk data Harian
    # UnitGroup=metric agar suhu dalam Celcius
    url = f"https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/{LOCATION}/{START_DATE}/{END_DATE}?unitGroup=metric&include=days&key={API_KEY}&contentType=json"

    print(f"Mengambil data untuk {LOCATION}...")
    
    try:
        response = requests.get(url)
        
        # Cek jika kena limit (Biasanya kode 429)
        if response.status_code == 429:
            print("❌ GAGAL: Kuota API harian habis! Coba lagi besok.")
            return
        
        if response.status_code != 200:
            print(f"Error: {response.text}")
            return

        data = response.json()
        days = data.get('days', [])
        
        print(f"Berhasil mendapatkan {len(days)} baris data.")

        # Koneksi Database
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor()

        # Loop data dan masukkan ke database
        count = 0
        for day_data in days:
            # Mapping data JSON ke Kolom Database
            # Perhatikan: Sesuaikan nama kolom dengan tabel historical_dataset kamu
            
            # Konversi tanggal string "2020-01-01" jadi day, month, year
            d_str = day_data['datetime']
            d_obj = date.fromisoformat(d_str)
            
            sql = """
            INSERT INTO historical_dataset 
            (day, month, year, tempmax, tempmin, temp, humidity, windspeed, sealevelpressure, conditions) 
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """
            
            val = (
                d_obj.day,
                d_obj.month,
                d_obj.year,
                day_data.get('tempmax'),
                day_data.get('tempmin'),
                day_data.get('temp'),
                day_data.get('humidity'),
                day_data.get('windspeed'),
                day_data.get('pressure'), # Visual crossing pakai key 'pressure'
                day_data.get('conditions')
            )
            
            try:
                cursor.execute(sql, val)
                count += 1
            except Exception as e:
                print(f"Gagal insert baris {d_str}: {e}")

        conn.commit()
        cursor.close()
        conn.close()
        print(f"✅ SUKSES! {count} data berhasil disimpan ke database.")

    except Exception as e:
        print(f"Terjadi kesalahan: {e}")

if __name__ == "__main__":
    fetch_and_save()