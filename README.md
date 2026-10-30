# Winn Gayrimenkul — ilk sürüm

Telefon ve bilgisayara uyumlu, React + Vite arayüzü ve Supabase Auth/Postgres kullanan başlangıç projesi.

## Özellikler
- E-posta ve şifreyle giriş
- Yönetici / emlak danışmanı rolleri
- Emlakçı yalnızca kendi portföy ve müşteri kayıtlarını görür; yönetici tüm kayıtları görür
- İlan ekleme, arama ve silme
- Müşteri ekleme ve silme
- Komisyon hesaplama
- Veritabanında Row Level Security (RLS) politikaları

## Kurulum

1. Supabase'de yeni bir proje oluşturun.
2. Supabase > SQL Editor bölümünde `supabase/schema.sql` dosyasının tamamını çalıştırın.
3. Supabase > Authentication > Users bölümünden yönetici e-posta hesabını oluşturun (kullanıcı daveti veya güvenli parola belirleme yöntemi kullanın).
4. Yönetici kullanıcısının UUID'sini Authentication > Users listesinden kopyalayın. SQL Editor'de aşağıdaki sorguyu kendi UUID'niz ve adınızla çalıştırın:

   ```sql
   update public.profiles
   set full_name = 'Winn Yönetici', role = 'admin'
   where id = 'AUTH-USER-UUID-BURAYA';
   ```

5. Authentication > Users üzerinden en fazla dört danışman hesabı daha oluşturun. Tetikleyici her yeni kullanıcı için otomatik olarak `agent` profili açar.
6. Node.js LTS kurulu bilgisayarda bu klasörde:

   ```bash
   cp .env.example .env
   ```

   `.env` dosyasına Supabase Project URL ve **publishable/anon** anahtarını girin. `service_role` anahtarını kesinlikle kullanmayın.
7. Terminalde:

   ```bash
   npm install
   npm run dev
   ```

8. Yayınlamak için `npm run build` komutuyla `dist/` klasörü oluşturun ve Vercel, Netlify veya benzeri statik hosting servisine yayınlayın. Hosting ortam değişkenlerine `VITE_SUPABASE_URL` ve `VITE_SUPABASE_ANON_KEY` ekleyin.

## Güvenlik notları
- Yetki denetimi yalnızca arayüzde değil, PostgreSQL RLS politikalarında da uygulanır.
- Kullanıcı kayıtlarını genel kayıt ekranıyla açmayın; hesapları Supabase panelinden yönetici oluştursun.
- İlk yönetici rolünü yalnızca güvenilir Supabase SQL Editor üzerinden atayın.
- Bu başlangıç sürümünde ilan fotoğraf yükleme, kullanıcı yönetim ekranı, denetim kayıtları, şifre sıfırlama akışı ve yayına alma işlemi henüz ekli değildir.
- 5 kullanıcı hedefi uygulama kodunda otomatik kota olarak zorlanmaz; beş hesap oluşturmak için operasyonel sınır olarak uygulanır.
- Komisyon ekranı tahmini hesap yapar; KDV veya mevzuat sınırlarını otomatik hesaplamaz.


## Winn logosu
Gönderdiğiniz Winn Gayrimenkul Yapı İnşaat logosu `public/winn-logo.jpeg` dosyasına eklendi; giriş ekranında ve sol menüde kullanılır.
