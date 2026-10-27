# Açılış yakalaması: gözlenen akış ve sınırlar

## Kaydın kapsamı

- Kaynak oturum `reference/opening_capture/capture.log` içinde 2.400 emülatör karesi (yaklaşık 40 saniye) olarak kayıtlı; ekran görüntüsü karşılaştırma kopyaları `reference/opening_capture/frames_png/` altında.
- `input_timeline.csv` kaydında yalnızca A düğmesi basışları var: kare 89, 239, 389, 539, 689, 839, 989, 1139, 1289, 1439, 1589, 1739, 1889, 2039, 2189 ve 2339. Her biri tek karelik; yön, B, Start ve Select basışı yok.
- `emulator_ppu/index.csv` 759 değişen PPU durumunu listeliyor. Bunlar kare kare video değildir; her ham dosyada 8.192 bayt pattern-table, 4.128 bayt nametable/palet kaydı bulunur.

## Seyrek PPU anlık görüntüsü zaman damgası

`reference/opening_reference_capture/ppu_index.csv` değişen PPU bayt durumlarını indeksler; yakalama betiği bu baytları her emülatör karesinden sonra okur ve yalnızca önceki okumadan farklıysa dosya yazar. Bu nedenle bir kare için kullanılan `ppu_snapshot_frame`, ham dosyanın son değiştiği kareyi gösterir; daha sonraki karede yeni dosya bulunmaması tek başına baytların eksik veya eski olduğu anlamına gelmez. Paket metadata'sındaki `ppu_byte_state_valid_from_frame`, `ppu_byte_state_valid_through_frame` ve `ppu_byte_state_applicable_at_capture_frame` alanları bu sabit durum aralığını belirtir.

Bu aralık yalnızca örneklenen pattern/nametable/palet baytlarının uygulanabilirliğini doğrular. PPU yazımlarının kare içindeki raster zamanını, CHR bank geçişlerini, `$2002` latch durumunu veya fiziksel OAM'ın ekrana kopyalanma anını doğrulamaz. Bunlar çözülmeden kare kompozisyonu piksel-doğru kabul edilmemelidir. `ppu_snapshot_timestamp_mismatches` metriği yalnızca hedef kare ile son PPU dosyasının zaman damgasının farklı olduğu kayıtları sayar; `ppu_byte_state_inapplicable_frames` ise aralığa bağlanamayan kaynakları sayar.

OAM tarafında paketlenen kaynak RAM karesi hedef karenin bir öncesidir (`ram_source_frame_offset: -1`). Bu dosya OAM gölge belleği baytlarını verir; `oam_display_timing_verified_at_capture_frame: false` alanı, bunların ekranda kullanılan fiziksel OAM ile zamanlama bakımından eşitlenmediğini açıkça belirtir.

## Gözlenen ekranlar

Kare sınırları, `screen_timeline.csv` içindeki değişen ekran örnekleri ve PNG incelemesine göredir; aradaki karelerde ekran sabit kalabilir veya örnekleme aralığındaki animasyon kareleri atlanmış olabilir.

| Yaklaşık kare aralığı | Görünen içerik | Kanıt / not |
|---|---|---|
| 0–139 | Futbol sahası animasyonu ve alt diyalog kutusu; kare 0'da metin “Kosuu...” diye başlıyor | Kare 0, `FCEU.poweron()` öncesinden kalan eski görüntü olabilir; soğuk açılış kanıtı sayılmaz. |
| 140–379 | Siyah zemin üzerinde yanıp sönen `TECMO THEATER` logosu | Kare 140'da FCEUX “Power on” ekran bildirimi de görünür; oyun grafiği değildir. |
| 380–809 | Saha çizgileri ve top süren/vuran oyuncu; alt diyalog kutusundaki yazı kademeli beliriyor | Örnek kare 690'da birden fazla diyalog satırı görünür. |
| 810–1025 | Siyah geçiş; ardından mavi portre alanı ve oyuncu bilgi yazıları | Kare 880 civarında `Oozora Tsubasa / Brezilya / Sao Paulo FC MF` okunuyor. |
| 1026–1547 | Hyuga'nın topa vurma animasyonu, diyalog kutusu ve kademeli yazı | Örnek karelerde `Hyuga-kun'dan Ani bir Tiger Tackle` metni görülüyor. |
| 1548–1779 | Hyuga portresi ve bilgi kartı, siyah fon | Kare 1610'da `Hyuga Kojiro` ve `Toho ... CF` okunuyor. |
| 1780–2117 | Şut animasyonu, renkli arka plan geçişleri ve alt diyalog kutusu | Örnek karelerde “İste/altın kilidin bitirici Twin şutu...” metni kademeli ilerliyor. |
| 2118–2399 | Taro Misaki portresi/bilgi kartına geçiş; oturum burada biter | `Taro Misaki / Nankatsu Lisesi MF` okunuyor. Başlık ya da seçim menüsü görünmüyor. |

## Sonuç

Bu kayıtta açılış animasyonu ve devamındaki karakter/diyalog sekansı gözleniyor; **KICKOFF / CONTINUE başlık menüsü veya takım/seçim ekranı yakalanmamış**. A basışları her 150 karede bir otomatik verildiğinden, geçişlerin kullanıcı girdisine mi yoksa oyunun kendi zamanlamasına mı bağlı olduğu bu kayıttan kesinleştirilemez. Kare 0'ın önceki emülatör görüntüsü olma ihtimali ve FCEUX bildirim katmanı nedeniyle kayıt, temiz güç açılışının piksel-doğru referansı değildir.

Godot açılış/başlık/hedef seçim ekranlarının kesin akışını çıkarmak için gereken yeni referans: FCEUX'te ROM'u gerçekten güç döngüsünden başlatan, ilk görüntü karesi sıfırlama sonrasında alınan, tuşlar zaman damgasıyla elle/denetimli kaydedilen bir oturum; başlık menüsüne gelene kadar A'ya otomatik basılmamalı. Mevcut PNG'ler yalnızca gözlem malzemesidir; orijinal varlık yerine kullanılmamalıdır.

## OAM gölge belleği değerlendirmesi

`ram_states/ram_NNNNN.bin` örnekleri CPU RAM `$0000–$07FF` alanıdır. İçlerindeki `$0200–$02FF` aralığı, NES OAM'ın beklenen 64 adet 4 baytlık (`Y, tile, attribute, X`) düzeniyle güçlü biçimde uyuşuyor: kayıtlarda çoğunlukla 39–64 görünür giriş var, tile/attribute değerleri sprite verisi gibi kümeleniyor ve değişen X/Y koordinatları görüntüdeki animasyonla eşleşiyor. Kare 803 civarında sahadaki oyuncu sprite'ları; 880 civarında Tsubasa portresi; 1290 civarında Hyuga vuruşu; 1610 ve 2190 civarında karakter bilgi portreleri buna örnek doğrulamalardır.

**Sonuç:** Emülatör yakalamasından OAM gölge belleğinin yeniden kurulması büyük olasılıkla mümkün; kare bazlı `$0200–$02FF` dökümleri sprite sıralaması, konum, tile ve attribute alanlarını veriyor. Bu, PPU'nun fiziksel OAM'ına doğrudan alınmış dump olarak henüz doğrulanmadı. Kesin doğrulama için aynı karelerde FCEUX OAM/Sprite Viewer veya emülatörün OAM belleği görünümüyle karşılaştırılmalı; eşlenen CHR pattern verisi ve palet de birlikte kullanılmalı. Ham RAM kaydı tek başına tam sprite görüntüsü değildir.

İnceleme, `ram_states/ram_*.bin` içindeki 2.397 adet 2 KiB kayda dayanıyor (aralık 0–2399); `$0200–$02FF` sayfasında 318 farklı içerik görüldü. Bu inceleme sırasında ortak `ram_state_index.csv` yeni bir yakalama tarafından yeniden oluşturulmaya başlanmış ve yalnızca başlık satırına düşmüştü; bu nedenle kare eşlemesi dosya adlarındaki `NNNNN` değerinden yapıldı. Önceki yakalamanın index dosyası şu anda mevcut değil.

## Güncel intro → başlık gözlemi

- İki ayrı temiz güç döngüsü yakalaması vardır; kare numaraları her yakalamanın kendi başlangıcına göredir. `reference/cold_start_title_input_probe/` içindeki otomatik probda `Start` frame 4700–4711'de tutulur ve başlık frame 4731'de görünür. `reference/opening_reference_capture/input_timeline.csv` içindeki yakalamada `Start` frame 4661–4667'de tutulur; Godot manifestindeki geçiş bu girişten sonra bir intro karesi ve 30 siyah kare oynatıp menüyü frame 4692'de gösterir. Bu kare sayılarını farklı yakalamalar arasında birbirinin yerine kullanma.
- Başlık ilk açıldığında seçim işareti `KICK OFF` yanındadır. 12 karelik `A` veya `B` denemeleri ekranı değiştirmedi; `Start` onayından sonra yaklaşık 15 kare içinde siyah geçiş başlar ve sonraki hikâye akışına geçilir.
- KICK OFF'tan sonra uzun hikâye/diyalog akışı başlıyor. Bu milestone için akış başlık menüsünde biter; KICK OFF veya CONTINUE onaylanmaz ve sonraki ekranlar kapsam dışıdır.
- Kayıt başlık karesinde PPU/RAM'ı ve girişleri eşlemek için kullanılır; PNG/GD/WAV dosyaları Godot runtime asset'i değildir.

## Eksik PPU register/mapper geçmişi

Mevcut PPU snapshot'ları kare sonu belleği içerir, fakat kare içinde yazılan `PPUCTRL`, `PPUSCROLL` ve MMC3 CHR bank kayıtlarının zamanını içermez. `tools/capture_ppu_register_writes.lua` bu yazımları FCEUX'te ayrı CSV olarak yakalamak için eklendi. `cpu_cycles` sütunu kare içi raster etkilerini çözümlemeye yardımcı olur; tek başına tamamlanmış PPU raster kaydı sayılmaz.
