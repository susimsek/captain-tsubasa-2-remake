# Archived GOAL progress log — 28 October 2026

> Historical snapshot preserved when the active `GOAL.md` was shortened.
> This log is not the source of current status; use the root `GOAL.md` and
> `PLANS.md` for that. Paths written as inline code remain project-root-relative.
> Markdown links in this file are relative to this `reference/` directory.

---

# Tamamlanan hedef: ROM mantığını Godot'a taşıyan açılış ve başlık ekranı

Kullanıcının sağladığı NES ROM'unu davranış ve içerik kaynağı kabul ederek soğuk açılıştan `KICK OFF` / `CONTINUE` başlık ekranına kadar olan Godot 4 dilimini tamamla. Bu hedef kapatıldı. Proje şimdi yeni hedef olarak taze `KICK OFF` akışında ilk maç komut ekranına kadar ilerleyecek; Continue akışı kapsam dışıdır.

## Etkin hedef: KICK OFF'tan ilk maç komut ekranına — 28 Ekim 2026

Kapsam, mevcut başlık ekranında seçili `KICK OFF` öğesini onaylamaktan taze
oyun akışını izleyerek ilk maçtaki Çalım/Pas/Şut komut paneline ulaşmaya kadar
genişletildi. Continue akışı ve ilk futbol aksiyonunu onaylamak kapsam dışıdır.
Önceki açılış hedefinin doğrulanmış sonucu yukarıda korunuyor. Bu yeni rota
Godot'ta kısmen bağlandı, ancak ilk maç menüsüne gerçek oyun akışıyla ulaşma ve
aynı girdide tam görsel/ses eşleşmesi henüz tamamlanmadı.

- 28 Ekim temiz-kopya denetimi: Godot 4.7.2 ile yalnız proje sahneleri,
  scriptleri, ROM'dan türetilmiş kaynaklar, palet ve ses varlıklarını içeren
  kopyaya import yapıldı; `.nes` ROM'u, `reference/diagnostics/` ve FCEUX
  dosyaları kopyada yoktu. Import ve kısa ana-sahne açılışı başarılı oldu.
  Aynı kopyadaki KICK OFF rota doğrulayıcısı matchup → MEETING → ID 2 → saha
  akışını çalıştırıp yine `first_action_menu_pending` durumunda durdu; eksik
  teşhis PPU dosyası doğru biçimde atlandı. Bu, mevcut akışın bu sınıra kadar
  ROM/emülatör dosyaları olmadan çalıştığını kanıtlar; ilk komut menüsünün
  üretim rotasında kurulmasını veya menü sonrasını kanıtlamaz. Kopya
  geçici bir dizinde oluşturuldu.
- Yeni `RomFreshKickoffCallerContinuation`, hash-korumalı bank-$00 byte'larıyla
  title KICK OFF dalından ID-1 beklemesi, eşleşme hazırlığı, `$812C` ses-kuyruğu
  yazımı ve `$83DC[0]=$02` ID-2 dispatch'ine kadar olan çağrı yolunu çözüyor.
  Odaklı Godot doğrulayıcı, `$55` yazımını ROM-only kaynak adımlayıcısındaki
  `$812F` sonrasıyla eşleştiriyor. Her modellenmemiş `JSR` için açık kaynak
  dönüş girdisi gerekiyor; alt yordam gövdeleri, bekleme/NMI/task stack'i ve
  mutlak kare/çevrim çalıştırılmıyor. Bileşen `KickoffRouteRuntime`'a bağlı
  değil; bu yüzden ses olayı henüz gerçek Godot rotasında üretilmiyor.
  `tools/diagnostics/verify_rom_fresh_kickoff_caller_continuation.gd` PASS.
- Slot-$05 period görevinin ROM-byte yürütümü artık `$DAAA`'dan ilk bank-$18
  worker girişine `$800C` kadar ulaşıyor: `$CBF1/$CF4F`, 22 `$CD7C`,
  `$CE2D`, bank-$1A `$8039/$904E`, `$DB24/$CB99/$DB34`, bank-$1C
  `$8003/$8B22`, 11 rakip kayıt pointer'ı ve ilk `$EF7F` wrapper. `$800C`'deki
  A/X/Y/P/SP, stack, mapper, RAM ve sıralı yazılar imzalı iki-pass FCEUX
  izindeki frame-8460 sınırıyla eşleşiyor;
  `tools/diagnostics/verify_rom_fresh_daaa_continuation.gd` PASS.
  Bu yürütücü hâlâ izole; önceki bütün route ve RAM reset başlangıcı baştan
  yürütülmüyor, üretim rotasına bağlı değil. Ayrı
  `RomFreshBank18WorkerPrefix`, önceki kaynak sonucundan başlayıp `$800C`'deki
  `$8851` sıçramasını ve worker'ı `$8886–$8888: JSR $C515` noktasına kadar
  yürütüyor; `$C515` trampoline'ını çalıştırmıyor. Çağrı girişinde A/X/Y/P,
  stack, mapper, task kaydı ve sıralı RAM yazıları iki sessiz FCEUX geçişiyle
  eşleşiyor; `tools/diagnostics/verify_rom_fresh_bank18_worker_prefix.gd`
  PASS. Yeni scheduler köprüsü gerçek `$8886: JSR $C515` çağrısını ayrı
  hash-korumalı bank-$18 spanıyla doğruluyor; çağrı zaten `$8888` dönüşünü
  stack'e koyduğu için `$CB0F` uygulaması bu dönüşü tekrar basmıyor. Kaynak
  slot-$01 yield'i ve slot-$05 dispatch'i türetilip period, `$DAAA` ve worker
  bileşenleri birleştiriliyor; `$CB0F` sonrasında slot-$05 kaydı
  `01 46 18 19`, stack penceresi `$0147-$0150` ise
  `00 FF 88 88 98 EF 1D 1C CB DA` oluyor. `$C515/$CB0F` girişindeki
  A/X/Y/P/SP ve mapper ile post-save görev kaydı/stack etkileri iki sessiz
  FCEUX geçişiyle doğrulanıyor; frame 8460'da
  `$C515` cycle offseti 27552, `$CB0F` offseti 27555;
  `tools/diagnostics/verify_rom_fresh_worker_yield_scheduler_bridge.gd` PASS.
  `RomGameplayTaskScheduler` için eklenen sınırlı birleştirme metodu,
  `$D11E->$C515` aralığındaki üç ROM-byte bileşeninin sıralı yazı deltalarını
  uyguluyor: period 9, `$DAAA` devamı 287, worker 7;
  toplam 303 yazı. Tam RAM görüntüsünü kopyalamıyor ve `$0000`, altı görev
  kaydı ya da `$001B` ready latch'e yazmayı reddediyor. Değişen baytları worker
  sonucuyla, continuation/worker yazı sırasını iki FCEUX geçişiyle doğruluyor.
  Bu, önceki `$D11E` route RAM'ini oluşturmaz; dokunulmayan adresler scheduler
  örneğindeki değerlerde kalır. Frame-8399 DAAA izi period görevindeki dokuz
  yazımdan sonra başladığı için o dokuz yazımın ayrı writer satırlarıyla
  karşılaştırması yok. Kaynak dilim burada, sonraki scheduler taramasından
  önce duruyor: gerekli NMI kenarı ve worker'ı devam ettirecek resume henüz
  modellenmedi. İkinci
  `$EF7F` çağrısı ile `$DAD0-$DAD9` hâlâ açık; `$DAD8` senaryo `$35` operandı,
  enqueue JSR'si `$DAD9`'dur. Bu bileşenler de izole ve önceki tüm reset/route yürütümünü,
  production entegrasyonunu veya ilk komut menüsünü kanıtlamıyor. Ayrıntılar
  `reference/rom_extract/gameplay/fresh_daaa_continuation_boundary_20261028.md`
  ve `reference/rom_extract/gameplay/fresh_bank18_worker_prefix_boundary_20261028.md`.
- Başlık çağrısındaki sabit `$C4B9` mapper helper'ı da 15 ROM baytını
  çalıştıran küçük bir kaynak bileşeniyle modellenip doğrulandı. İlk dört çağrı
  yerinin `$C4B9` JSR baytları paketlenmiş `$80DF–$815C` spanından; yeni `$8938`
  callsite'ı `$8920–$893E` spanından denetlenir;
  helper, stack'ten RTS dönüşünü ve `$8000/$8001` MMC3 yazılarını çıkarıyor.
  Beş callsite verifier'ı Godot 4.7.2'de PASS. Çağrı olayını ya da canlı
  mapper değişimini üretmez ve henüz route'a bağlı değildir:
  `reference/rom_extract/gameplay/fresh_kickoff_mapper_helper_20261028.md`.
- Yeni `RomFreshMatchSelectorExecutor`, ROM baytlarıyla `$80FA JSR $A20F`
  çağrısından `$80FD` dönüşüne kadar match-0 kolunu yürütür. `$A20F->$A86E`
  dalı `$A8B7 JMP $A138` trampolinini izler; `$A138` ROM'daki 4.944 baytı
  `$6000-$734F` PRG RAM'ine kopyalar ve `$A8BB-$A8CD` 11 oyuncu kimliğini
  kayıtlara yazar. Gerçek `$A8CD RTS` ve `$A8B6 RTS` stack/register/flag
  sonuçlarıyla doğrulandı; kaynaklar/hash'ler manifestte, Godot 4.7.2 odaklı
  doğrulayıcı PASS. Girdi olarak açık `$26=0`, `$22/$23/$25`, `$C4B9` sonrası
  A/X/Y/P/SP ve JSR stack'i gerekir; ROM kopyası için `$Y=0` zorunludur.
  Ardından `RomFreshMatchNormalizeExecutor`, bu sonuçtan `$80FD-$810F`
  caller kodunu ve `$810C->$C4B9` mapper helper'ını yürütüp `$810F->$A20C`
  çağrısını `$A8B6 RTS->$8112` dönüşüne kadar taşır. `$26=0` için tüm 256
  `$E4` bayt değeri karşılaştırılarak `BCS $A8A8` dalı ve son register/flag
  çıktısı kanıtlandı; hiçbir `$E4` değeri ya da iz RAM'i kullanılmadı. Godot
  4.7.2 odaklı doğrulayıcı PASS. Bu bileşen de izole; route kaynaklı çağrı
  makbuzu üretmiyor ve `KickoffRouteRuntime`'a bağlı değil. Sonraki
  `$8114 JSR $8920` prefix'i `$893B LDA $78 / BNE $893B` bekleme koşuluna kadar
  ilerledi. `$9DEE` gerçek RTS'i, `$8938->$C4B9` de bank-$06 seçip gerçek
  RTS'i geçiyor; `$8920`'ın kendisi dönmüyor çünkü `$78` için kaynak-sahipli
  bir değer/olay yok. Bu prefix 232 çevrimde duruyor; bilinen ve sembolik
  olmayan bir bekleme süresi uydurulmuyor. `$78` kaynağı ve devam/yeniden
  başlatma açık. Ayrıntı:
  `reference/rom_extract/gameplay/fresh_kickoff_match_selector_executor_20261028.md`,
  `reference/rom_extract/gameplay/fresh_kickoff_match_normalize_executor_20261028.md`,
  `reference/rom_extract/gameplay/fresh_kickoff_match_setup_prefix_20261028.md`,
  `tools/diagnostics/verify_rom_fresh_match_selector_executor.gd` ve
  `tools/diagnostics/verify_rom_fresh_match_normalize_executor.gd`,
  `tools/diagnostics/verify_rom_fresh_match_preset_loader_prefix.gd` ve
  `tools/diagnostics/verify_rom_fixed_mapper_select_helper.gd`.

- 28 Ekim ek kaynak incelemesinde Japonca さんぱうろFC sitesi, takım kadroları
  ve oyuncu seviye değerleri için yararlı bir karşılaştırma kaynağı olarak
  bulundu. Site değerleri CT4 düzenine çevirdiğini belirtiyor; ROM içi oyuncu
  kimliği, kayıt pointer'ı, ham tablo, maç kodu veya sahne kodu vermiyor.
  Çince Hack CT2 araç günlükleri ve adres/animasyon listeleri düzenleme
  kategorileri ile bazı etiketleri gösteriyor, ancak bu Türkçe ROM için tam
  doğrulanmış kod haritası sunmuyor. Kaynak sınıfları ve sınırları
  `reference/rom_extract/gameplay/first_match_external_reverse_engineering_review_20261027.md`
  ile `online_sources.md` içinde; dış tablolar runtime verisi olarak
  kullanılmıyor. Ek denetimde, commit-pinned CT2 6502 dökümünün bank `$18`
  listesindeki `$8852` menü çizicisi / `$88B9` satır paketi etiketleri hedef
  ROM'da karşılaştırıldı: açıklamalı 154 komutun 302 makine kodu baytı
  `$8852–$89A2` aralığında aynı. Döküm `$885E–$887B` bölümünde bazı makine
  baytlarını listelemediği ve canlı görev/PPU izi vermediği için yalnız adres
  bulma ve etiket karşılaştırma yardımcısıdır; bu çağrı ve zamanlamayı çözmez.
- İlk komut panelinin tanı amaçlı `+6` sat kaydırması ROM yerleşiminden
  türetilemiyor: descriptor `$03` ilk kenarı PPU `$2252`/y=144'e koyarken,
  izole Godot paneli 240→224 crop sonrası y=136'da çiziyor. FCEUX karesi canlı
  raster durumundan; izole panel karesi sıfır scroll ve raster olmadan
  alındığından farkın kaynağı kanıtlanmadı. Crop belgelenmiş sekiz overscan
  satırını açıklar, ekstra altı satırı değil; runtime offseti uygulanmıyor.
  Karşılaştırma eksik IRQ scanline/dot/ilk-piksel izi bekliyor:
  `reference/rom_extract/gameplay/first_menu_visible_output_comparison_boundary_20261028.md`.
- Türkçe topluluk kaynaklarından oyuncu kodu ve slot eşleşmesi de bulundu:
  “Ct-2 Cheat Kod yazımı” listesindeki São Paulo oyuncu kimlikleri, ROM'daki
  maç-00 kadro baytları `02 03 04 05 06 07 08 09 0A 01 0B 00` ile aynı sırada;
  listedeki `$0300`–`$0378` RAM kayıt başlangıçları da ROM'dan çıkarılmış ilk
  11 kayıt pointer'ıyla (her oyuncuda `+$0C`) eşleşiyor. Özel hareket yazısı
  Tsubasa/Misaki hareket listesi ofsetlerini ve kodlarını veriyor; örnek
  diziler `0x3935D` ve `0x39368`'de ROM'la byte-byte aynı. Önceden bulunan
  Tsubasa isim-table ofseti `0x3F519` (`01 02 03 FC`) ve Drive şut sahnesi
  paylaşımındaki `0x21D0C` pointer alanı / `0x22B50` bytecode alıntısı da
  eşleşiyor. `$0026/$0027` maç/devre listeleri ROM dosya ofseti değil, emulator
  RAM hileleridir; yerel analiz taze maç için `$0026=0/$0027=0` değerlerini
  destekliyor. Oyuncu AI arşivi indirilirken HTTP 403 döndü, içeriği açılamadı.
  Bu bulgular oyuncu kimlikleri ve sonraki özel hareket araştırması için
  yararlı, fakat tüm maç/sahne kodlarını veya sahne yürütme mantığını veren
  eksiksiz bir dış kaynak bulunamadı; ilk menünün görev/callback akışını da
  çözmüyor. Byte karşılaştırmaları ve güven sınırları
  `reference/rom_extract/gameplay/first_match_external_reverse_engineering_review_20261027.md`
  ile `online_sources.md` içinde.
- Üç yeni dar kapsamlı ROM-kaynaklı parça Godot 4.7.2'de ayrı doğrulandı:
  bank-$10 senaryo-$35 okuyucusu `$DAD8` çağrısından `$F9`, `$8097` callback
  görev tohumu isteği ve kök `$FB` sonlandırmasına kadar ilerliyor;
  `$A38A/$A390` aktör durum yorumlayıcısı bekleme/entegrasyon/hold sırasını
  yürütüyor; RNG olay köprüsü caller tarafından verilen `$A117/$C9C5/$DB05`
  kaynak olaylarından ROM-kaynaklı alıcı ve oyuncu durumunu çıkarıyor. Bunlar
  sırasıyla `tools/diagnostics/verify_rom_bank10_scenario_task_runtime.gd`,
  `verify_rom_actor_state_interpreter.gd` ve
  `verify_kickoff_rng_source_event_stream.gd` ile PASS aldı. Bu parçalar
  production `KickoffRouteRuntime` akışına bağlanmış değil: görev scheduler'ı,
  callback `$814C/$8327`, aktör worker'ı, canlı RNG operand olayları ve PPU
  kuyruğu birlikte yürütülmüyor; ilk maç komut menüsü hâlâ gerçek rotada
  üretilmiyor. Odaklı rota doğrulaması da bunu açıkça sınırlar.
- `$E3CA` alan girdisi için yeni sessiz FCEUX izi, imzalı frame-8399 bellek-içi
  checkpoint'inden iki kez aynı sonucu verdi: frame 8461–8953 boyunca 493
  çağrıda `$001C & $0F` sıfır; `$E3CA` hareket/stat dalını atlayıp `$E406`'dan
  dönüyor ve `$0642/$0643` koordinatları değişmiyor. Frame 8893'teki B girdisi
  de bu yön tuşu yolunu tetiklemiyor. Bu, ölçülen rota için hareket simülatörü
  ihtiyacını daraltır; canlı scheduler/callback ve menü geçişini çözmez. İz ve
  kaynak dalı `reference/rom_extract/gameplay/first_command_e3ca_no_direction_trace_20261028.md`
  içinde.
- Fresh animation `$8F` için `$F1 → $80AA` ROM constructor'ı beş 21-byte aktör
  kaydını hash-korumalı `$88E4/$A1B4/$AC47` tablolarından kuruyor. İlk
  `$83D9` appearance `$F7` komutu `$B30E/$B310/$B312` kaynaklarından sırasıyla
  `$B8/$BA/$B9` sprite descriptor ve `$FF` hold timer üretiyor. İki odaklı
  Godot doğrulaması geçti. Hareket kökleri `$A723/$A72C` de artık `$01`
  hız/zamanlayıcı ve `$04` self-loop komutlarıyla, `$852A/$85F2` fixed-point
  integratörünü kullanarak dört `$8F` kaydına uygulanıyor. İlk-tick kayıtları
  frame-8482 FCEUX trace'iyle eşleşti; tam bir döngü ve aktör/appearance
  doğrulamaları geçti. Bunlar izole bileşenlerdir; canlı scheduler/cadence,
  sonraki appearance komutları, OAM çizimi ve production route entegrasyonu
  hâlâ açık. Kaynak ve sınırlar:
  `reference/rom_extract/gameplay/actor_packet_constructor/f1_actor_record_constructor_slice_20261028.md`,
  `reference/rom_extract/gameplay/actor_state_interpreter/fresh_actor_8f_appearance_root_slice_20261028.md`,
  `reference/rom_extract/gameplay/actor_state_interpreter/fresh_actor_8f_motion_root_slice_20261028.md`.

- Cutscene ID 1 ve 2'nin ROM pointer spanları byte-byte korundu. ROM bank-0
  vector tablosu ve canlı dispatch kanıtı `$FC`'nin `$8837` handler'ına
  gittiğini ve script pointer'ını yalnız bir byte ilerlettiğini doğruluyor;
  eski counted-payload parse'ı geçersizdi. Düzeltilmiş lineer `$FF` sınırları
  pointer spanlarıyla aynı: ID 1 `$A2A1–$A625` (901 byte, 222 event), ID 2
  `$A626–$A6B3` (142 byte, 45 event). Kaynak adresleri/hash'leri
  `reference/rom_extract/gameplay/kickoff_cutscene_01.json` ve
  `kickoff_cutscene_02.json` içinde; yeni indeksler
  `assets/gameplay/rom_logic/kickoff_cutscene_01_events.json` ve
  `kickoff_cutscene_02_events.json` içinde. Bunlar komut sırasını doğrular,
  kare zamanlamasını veya Godot davranışını değil.
- Sessiz FCEUX rotasının kullanılabilir tam uç-nokta dosyaları
  `reference/diagnostics/kickoff_select_test_20261027/` altındadır; 8953
  başlangıç komut paneli ve 9042 durağan kontrol noktası gözlem/doğrulama
  referansıdır. Screenshot/WAV runtime varlığı değildir.
- 28 Ekim kaynak-bileşim denetimi, `$35/$36/$1E/$44` senaryolarındaki sekiz
  callback kaydını ROM pointer tablosu ve stream başlıklarıyla çözüp iki sessiz
  FCEUX izindeki sırayla eşleştirdi. Bu, callback akışını doğrular; çalışma
  zamanı sıralaması sağlamaz. Önceki `$CA97` slot `$0001` engeli artık ayrı
  ROM-kaynaklı root-task bootstrap modeliyle çözüldü: `$01/$05/$09` kayıtları,
  stack devamları ve ilk scan'de `$01` dispatch'i tanısal olarak doğrulandı.
  Ayrı `RomGameplayTaskScheduler` yalnız slot `$01` başlangıcının
  `$CA22–$CA51` opcode dilimini ilk yield'e kadar gerçekten yürütür; bu bir
  tam root-task yürütücüsü değildir ve NMI cadence'i üretmez. Model/runner
  hâlâ `KickoffRouteRuntime`'a bağlı olmadığından production rota ilerlemesi
  sağlamaz. Sonraki `$8327` yerleşimi
  önceki callback'lerden üretilen canlı `$05CD` ve task/stack continuation
  durumunu gerektiriyor. Kompozisyon ve zamanlayıcı denetimleri
  `reference/rom_extract/gameplay/first_command_live_route_composition_boundary_20261028.md`
  ile `fixed_task_scheduler_scan_audit_20261028.md` içinde. İki-pass FCEUX
  kayıtları frame 8399'da imzası kontrol edilmiş, bellekteki anonim save-state
  yüklenerek alındı; her tekrar baştan başlatılmadı ve numaralı kullanıcı
  yuvaları kullanılmadı.
  FCEUX Lua'da aynı anonim state'i birden çok kez yüklemek için gereken
  `savestate.persist(state)` çağrısı 17 çok-pass gameplay trace betiğine eklendi;
  statik taramada hepsinde bulundu. Arşivlenmiş iz çıktıları bu kaynak
  değişikliğinden sonra yeniden üretilmedi. Bu anonim kayıtlar yalnız aynı Lua
  oturumunda yaşar; her yeni betik yine frame 8399'a kadar ısınır. Kurulu CLI
  `.fcs` dosya yolu değil numaralı slot argümanı bekliyor; ayrı çalıştırmalar
  arasında numarasız dosya kullanımı FCEUX GUI'sinden elle Save State As / Load
  State From ile yapılabilir. Uygulama ve doğrulama kuralları `AGENTS.md` içinde.
- Frame 8399 checkpoint'inden alınan ek sessiz iz, slot `$0001`'in frame
  8400–8457 arasındaki 58 adet bir-tick beklemesini ROM çağrılarına bağladı:
  8400–8442'de `$82B7`, 8443–8457'de `$9A06`; her iki çağrı da ROM'da
  `LDA #$01; JSR $9FA8` dizisidir. `$9FA8` gecikmeyi `$0019`'a alır, `$9FE0`
  görev kaydına yazar ve `$9EF7` sonraki scheduler taramasında azaltır. Bu,
  checkpoint sonrası yinelenen bekleme mantığını açıklar; slotun önceki
  bootstrap/çağrı bağlamını veya Godot rota entegrasyonunu çözmez. İki replay
  6.139 olay ve 62.357 yazma ile eşleşti; ayrıntı ve doğrulayıcı
  `first_command_task_wait_call_trace_20261028.md` içindedir.
- B→panel ROM call chain'i statik kod ve saklı muted trace'lerle artık
  sınırlanabildi: `$E349` sol-possession B dalı `$44/$70` callback'ini açıyor;
  `$8327/$8525` worker'ı `$05CD` üzerinden yerleşim/packet hazırlıyor; `$D5C3`
  `$02/$03` descriptor'larını seçiyor; bank-$18 `$8852/$88B9` satırları `$04A5`
  PPU kuyruğuna yazıyor. Queue tüketicisi `$C951`'dir. Saklı izde ilk panel
  paketi frame 8936'da kuyruğa giriyor, son PPU paketi frame 8945'te commit
  oluyor ve frame 8953 panelin ilk tam örneklenmiş görüntüsü. Bunlar test edilen
  girişin gözlem çerçeveleridir, runtime bekleme sabiti değildir. Önceki
  callback tarihçesinden canlı `$05CD` ile menü dinamik alanları için `$0441`/
  oyuncu verisi hâlâ production route'ta üretilmiyor; bu zincir Godot'a bağlı
  değildir. Detaylar `first_menu_visible_output_comparison_boundary_20261028.md`
  ve `first_command_menu_wait_and_stamina_trace_20261028.md` ile ilişkilidir.
- Root-task denetimi artık ROM NMI vektörünü `$FFFA→$C500→$C76E`, normal
  handler'ın `$2000.7` kapatma/vblank temizleme/ready-bit yazma/yeniden açma
  sırasını ve özel bank-$02 yolunu da byte-byte doğruluyor. Godot tanı modeli
  yalnızca dışarıdan verilen PPU NMI olayını ROM `$2000.7`/`$001B.6` durumuna
  göre eşliyor; kenar veya sabit kare/cycle takvimi üretmiyor. İki iz geçişinde
  59 özel kare, frame 8459'daki latch boşluğu ve 493 normal set/consume karesi
  doğrulandı. Bu root-task body'lerini ya da production scheduler'ı yürütmez.
  Doğrulayıcı Godot 4.7.2'de geçti; route izinde CPU-cycle NMI başlangıcı hâlâ
  ölçülmedi. Ayrı `RomNtscPpuVblankNmiClock` bileşeni şimdi NTSC dot/cycle
  ilerlemesi, `$2000.7`, iki-dot NMI çıkış gecikmesi, `$2002` race/status clear,
  `$2001` render-enable gecikmesi ve odd-frame skip davranışını izole biçimde
  yürütüp odaklı verifier'dan geçti. Bu, PPU line edge modelidir; CPU NMI
  örneklemesini, ROM handler'ını veya gameplay scheduler'ını çalıştırmaz ve
  `KickoffRouteRuntime`'a bağlı değildir.
  Çift izde frame 8459, `$0020` PPUCTRL gölgesini `$08→$88` cycle 15563'te
  (`$98D9`) ve `$88→$08` cycle 20739'da (`$A2C1`) değiştirirken `$001B` ready
  yazarı yok. İz PPU dot/scanline, vblank veya NMI-pending kenarını kaydetmediği
  için bu yalnızca faz-gated NMI olasılığını daraltır. Ayrı PPU/MMC3 izinde
  92.992 bus satırının tüm `ppu_scanline`/`ppu_dot` değerleri ve 554 frame-edge
  satırının tüm son koordinatları `-1`; dolayısıyla bileşene route başlangıç
  fazı veremez ve frame-8459 boşluğunu açıklamaz. Üretimde kullanılacak NMI
  kenarı/ready teslimi hâlâ yok; bunu frame numaralarından üretme. Ayrıntılar
  `reference/rom_extract/gameplay/first_command_root_task_bootstrap_and_nmi_20261028.md`
  ve `reference/rom_extract/gameplay/first_command_ntsc_ppu_vblank_nmi_clock_20261028.md`.
  Buna ek olarak `scripts/gameplay/rom_gameplay_task_scheduler.gd`, hash-kontrollü
  proje kaynaklarından bootstrap/task kayıtlarını kuran, dışarıdan sağlanan NMI
  olayını kabul eden ve ROM slot sırasıyla tek scheduler taraması yapan sınırlı
  bir runtime hizmeti sağlar. `$8097` callback seed'i ile doğrulanmış yield/
  resume/finish bağlamını da taşır; genel CPU/task-body yürütmez ve NMI sıklığı
  üretmez. Ek bir sınırlı ROM-opcode yürütücüsü `$CA22–$CA51` slot-`$01`
  başlangıcını ilk `$CB0F` yield'ine kadar işler; register ve `$01: 01 26 00 01`
  task kaydı muted FCEUX izindeki aynı-input durumla karşılaştırılır. Bu tüm
  task body'lerini yürütmez. Yeni `RomRootSlot01ContinuationRuntime`, ROM
  `$CA4D–$CA5A` döngüsünden `$EE9F/$E3CA` çağrı istekleri ile `$CB0F` yield
  sözleşmesini üretir; callee gövdelerini yürütmez ve production rotaya bağlı
  değildir. Odaklı verifier geçti. `KickoffRouteRuntime` bu sınırlı kaynağı artık
  `_initialize_fresh_match_context()` içinde kullanıp slot `$05` girişini
  çıkarıyor; bu tam rota entegrasyonu değildir. Ayrıntı
  `reference/rom_extract/gameplay/first_root_slot01_startup_runtime_20261028.md`
  içinde. Odaklı doğrulayıcı
  `tools/diagnostics/verify_rom_gameplay_task_scheduler_runtime.gd` geçmiştir.
- Taze başlangıç callback sınırının kaynak hesabı düzeltildi: `$A2AF`,
  `$AA06`'yı `$0468` başlangıcıyla çağırır; `$98` byte'lık ilk çevrim ve
  A'nın yeniden yüklenmediği iki 256-byte çevrimi toplam 664 byte temizleyerek
  `$06FF`'te biter. Böylece ilk `$35/$3A` callback'inden önce `$05CD/$05CE`
  sıfırdır. Yeni `RomFirstFreshCallbackSourceComponent` ayrıca ROM'dan
  `$35/$3A → $89F3 → $81A7 → $8327` kaynak zincirini çözüp `$8327` formülünün
  bu girişte `$05CE=0`, sonraki `$05CD=$A0` üreteceğini sınar. Bu sınırlı bir
  kaynak projeksiyonudur: callback task'ını çağırmaz, slot `$15` dispatch'ini,
  `$856F→$C515→$CB0F` yield/resume yolunu veya canlı route zamanlamasını
  yürütmez; `KickoffRouteRuntime`'a bağlı değildir. Düzeltme ayrıca önceki
  dokümanlardaki hatalı `$0468-$062F` aralığını giderir. Kaynak ve verifier:
  `reference/rom_extract/gameplay/first_fresh_callback_05cd_source_component_20261028.md`,
  `tools/diagnostics/verify_first_fresh_callback_source_component.gd`.
  Yeni `RomFreshKickoffEntryContextBuilder`, hash-kontrollü reset, KICK OFF,
  `$A20F/$A86E` ve task-scheduler kaynaklarından match `$26`, period `$27`,
  opponent `$2B` ile slot `$05` dispatch PC/SP'sini türetip typed bağlam olarak
  üretiyor. `KickoffRouteRuntime` bu bağlamı mevcut ID-2 dönüş katlamasında
  kullanıyor; Godot 4.7.2 builder verifier'ı ROM formüllerini frame-4692'den
  başlayan iki-pass iz ile karşılaştırıyor. Route wiring verifier'ı hâlâ
  yalnız menü-pending sınırına ulaşıyor ve canlı `$8327/$05CD` callback olayı
  üretmiyor. Builder bir kaynak state projeksiyonudur; kesin scheduler/NMI
  timing'i değil. `$DAAA` sonrasındaki `$CBF1/$CF4F/$CE2D/$8039/$DB24/$EF7F`
  yardımcı çağrıları, senaryo `$35`, `$8097` seed'i ve `$3A→$8327` callback'i
  henüz canlı route'ta çalıştırılmıyor. Ayrıntılar:
  `reference/rom_extract/gameplay/fresh_kickoff_entry_context_trace_20261028.md`,
  `scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd`,
  `tools/diagnostics/verify_rom_fresh_kickoff_entry_context_builder.gd`,
  `reference/rom_extract/gameplay/first_fresh_callback_execution_boundary_20261028.md`,
  `tools/diagnostics/verify_first_fresh_callback_execution_boundary.gd`.
- Taze KICK OFF bağlamı için sessiz iki-pass iz, frame 4692 anonim state'inden
  başlatıldı ve frame 4693'teki KICK OFF girdisinden ilk slot-$05 `$D11E`
  dispatch'ine kadar sürdü (18.507 sn). Her iki geçişte `$A86E` `$0026=$00`
  okudu, `$A8AF-$A8B6` `$002B=$03` yazdı, `$8105` `$0027=$00` yazdı ve slot
  `$05` `$D11E / SP=$52` konumunda seçildi; iki olay izi ve bellek erişim izi
  eşleşti. Her iki geçişte `$0026` için yazım görülmedi; resetten kare 4692'ye
  kadarki sıfır başlangıcı ayrı ROM reset analiziyle destekleniyor. Bu, kaynak
  bağlam üreticisine girdi sağlar; iz RAM'i runtime girdisi değildir ve
  üretim rota zamanlamasını çözmez. İz/verifier notu:
  `reference/rom_extract/gameplay/fresh_kickoff_entry_context_trace_20261028.md`,
  `tools/diagnostics/run_fresh_kickoff_entry_context_trace.py`.
- Kaynak-sıra denetimi mevcut kaba geçişlerde scheduler için güvenli bir
  tetikleyici olmadığını gösterdi: izde ID-2 Select 8443'te, root task scheduler
  8460'ta, ilk `$35/$3A` callback'i 8467'de, A/B beklemesindeki A ise 8593'te.
  Yeni sessiz iki-pass iz, `$A2AF`'i 8458'de, `$AA06`'yı 8459'da ve
  `$C557→$C6BE→$C6E8→$CA97`
  handoff'unu 8460'da doğrudan yakaladı; checkpoint imzası ve 6.086 olay /
  62.357 yazma her iki geçişte eşleşti. Bu, önceki "tam PC/çevrim kancası yok"
  ifadesini geçersiz kılar; ayrıntı
  `reference/rom_extract/gameplay/fresh_match_scheduler_handoff_trace_20261028.md`
  içindedir. Scheduler izi ayrıca slot `$01` yield'inden sonra `$05`, sonra
  `$09` taramasına geçtiğini doğruladı; runtime modeli ve odaklı doğrulayıcı bu
  imleç sırasını artık koruyor. İlk slot-`$01` yield'inden sonraki kaynak
  devamı `$CA52`'de `$EE9F` actor-update çağrısı, `$E3CA` holder/input çağrısı
  ve `$CA4D`'ye dönüş yapıyor; döngü `$CA4F`'te A=`$01` ile tekrar `$CB0F`'te
  yield ediyor. Caller'ın bu dönüş/yield sözleşmesi artık
  `RomRootSlot01ContinuationRuntime` ile modellenip scheduler diliminde
  doğrulandı; `$EE9F/$E3CA` gövdeleri, yazımları, NMI cadence'i ve production
  rota entegrasyonu hâlâ açık. Aynı-input
  callback izi ilk `$35/$3A` görevini `$8097→$814C→$81A7→$8327→$8525` yolunda
  doğruluyor; `$8525` yield/resume sonrasında frame 8479'da `$05CD=$00`'dan
  `$05CE=$00/$05CD=$A0` üretiyor. Kare ve RAM değerleri yalnız doğrulama
  ölçüsüdür. Önceki callback geçmişi, coroutine stack/bank durumu ve NMI-ready
  devamı üretilmeden bu callback'i doğrudan Godot sunumuna çağırmak doğru
  olmaz. Ayrıntılar `first_root_slot01_startup_runtime_20261028.md` ve
  `first_command_callback_scheduler_trace_20261028.md` içindedir.
  `KickoffRouteRuntime` cutscene-2 dönüşünde
  sınırlı bootstrap → slot `$01` ilk yield → slot `$05` `$D11E–$DAAA` source
  projection'ını çalıştırıp `$0629` sonucunu `$DB24/$DB34` context resolver'ına
  veriyor. Fakat `$82C6→$C557` caller/handoff yolunu ve bu root-task'ların canlı
  source zamanlamasını yürütmüyor; handoff executor da henüz route'a bağlanmadı.
  ROM `$DAAA→$DB24→$DB34` önce takım/
  formasyon/possession bağlamını kurup senaryo `$35`'i başlatıyor; ardından
  `$001C & $C0` ile A/B'nin basılı tutulmasını bekliyor. Bu beklemeden sonra
  `$0441` holder'ı ve `$DC07` 22 oyuncu pozisyonunu kuruyor. Godot rotası artık
  takım/formasyon/possession bağlamını ID-2 dönüşünde çözüyor, oyuncu
  pozisyonlarını ise A/B basılı girişi görüldüğünde kuruyor; A/B durumu `$001C`
  bitleriyle modelleniyor. Bu, görev/callback akışını çalıştırmak yerine ROM
  mantığını bu sınırda katlayan bir projeksiyon; senaryo `$35`, receiver/RNG,
  field callbacks ve tam input poll fazı hâlâ production route'a bağlı değil.
  Kaynaklar:
  `fresh_kickoff_0629_selector_source_audit_20261028.md`,
  `first_command_root_task_bootstrap_and_nmi_20261028.md`,
  `first_command_callback_scheduler_trace_20261028.md`.
- `RomFreshMatchHandoffExecutor`, `$82C6→$82DF→$815D→$8017→$A203→$A2AF→$AA06→$C557`
  için hash-kontrollü ROM aralıklarını ve kaynak adresli RAM/APU/mapper yazım
  planını koruyor. Dört sunum yardımcısı için Godot etkisi almadıkça tam
  handoff'u modellediğini söylemiyor; verdiği `$C6BE` task yazımları uygulanmış
  değil ve sonraki `$C6E5→$CF1F` çağrısı çözümlenmedi. Bu executor henüz rota
  runtime'ına bağlı değil. Odaklı verifier doğal/Select çıkışlarını, bekleyen
  helper sınırlarını ve yazım aralıklarını Godot 4.7.2'de doğruluyor.
  `reference/rom_extract/gameplay/fresh_match_handoff/README.md` ve
  `tools/diagnostics/verify_rom_fresh_match_handoff_executor.gd`.
- Ayrı `RomFreshPeriodTask`, slot `$05`'in `$D11E–$D182` ROM-opcode yolunu yalnız
  caller kaynaklı fresh period `$0027=0` ve opponent `$002B=3` için `$DAAA`'ya
  kadar yürütüyor. Doğrulanan sonuç `$0629=0`, `$05F7–$05F9=$B4/$00/$00` ve
  `SP=$50`; `$D183–$D184` kamera tablosu ayrıca hash-kontrollü. Bu sınırlı yol
  artık rota context projection'ında çağrılıyor; task scheduler'ı veya diğer
  rakip/dönem dallarını yürütmüyor. Odaklı verifier:
  `tools/diagnostics/verify_rom_fresh_period_task.gd`; kaynak notu
  `reference/rom_extract/gameplay/fresh_period_task/README.md`.
- `$0638`'i sıfıra çeken kaynağı erken checkpoint'li sessiz iki-pass iz belirledi:
  frame 8220'de anonim FCEUX save-state RAM/PPU/mapper imzasıyla doğrulandı;
  frame 8256'da `$26→$00` tek yazımı PC `$9B00`'da oluştu. ROM çağrı zinciri
  `$8585→$997E→$9B07→$9981→$9AB8→$9AFD`; `$9AB8`, önceden seçilmiş `$0048=$06`
  için `$B060` bank-6 ROM satırını açtı ve `$9AFD` satırın 14. `$00` baytını
  `$0638`'e kopyaladı. İki kısa replay eşleşti; numaralı kullanıcı slotu
  kullanılmadı. `$0048=$06` için ROM-only bir yol bulundu: ID2 akışı `F9 02`
  çalıştırıyor; `$8824→$8AF7`, background-2 ROM kaydının byte 2'sindeki `$06`
  değerini `$8B4C`'te `$0048`'e kopyalıyor. Palette `$06` ROM byte'ları da
  korunmuş. Frame 8100 RAM durumu `$0048=$1A`, frame 8125 `$06`, frame 8134
  `$0049=$0E`; fakat PC/yazma izi `$8B4C`'ü bu belirli frame değişimine
  bağlamıyor. Sessiz FCEUX izi ROM/Lua yüklenmeden takıldı. RAM snapshot'larını
  runtime başlangıç değeri olarak kullanma. `$0638` kopya yolunun Godot route'a
  bağlanması da açık. Ayrıntı
  `reference/diagnostics/first_command_0638_ownership_trace_20261028_084559_utc/`.
  `$0048` RAM aralığı ve başarısız iz sınırı
  `reference/rom_extract/gameplay/first_command_live_route_composition_boundary_20261028.md` içinde.
- Aynı-input frame 8953 görünür çıktı denetimi, FCEUX ekranını yalnızca doğrulama
  referansı olarak Godot'un ROM-derived arka plan yakalamasıyla karşılaştırıyor.
  İlk denetimde 31.929/61.440 RGB pikseli (%51,968) eşleşmişti; analizde eksik
  orta-kare IRQ viewport geçişi bulundu. Godot artık ROM-derived başlangıç
  `$2000/$2005` konumundan FCEUX NewPPU iziyle doğrulanan `$2006=$2200` satır-124
  yüklemesine ve satır-125 sıfır scroll'una geçiyor. Aynı test girdisiyle yeni
  arka plan karşılaştırması 53.416/61.440 piksel (%86,940), 8.024 fark ve
  ortalama mutlak kanal hatası 21,7685 verdi. Bu satır tabanlı renderer yaklaşımı
  ilk değişen pikseli veya fiziksel 2C02 zamanlamasını kanıtlamaz. Tam viewport
  hâlâ oyuncu/aktör katmanını, skor/enerji panellerini ve ilk komut menüsünü
  runtime rotasında üretmiyor; bu nedenle ölçüm tam ekran eşleşmesi değildir.
  Araç `tools/diagnostics/compare_first_menu_visible_output.gd`; doğrulama
  görüntüsü `/tmp/ct2_first_menu_visible_output_diff_8953.png`.
- İlk menü paneli ayrıca ROM-derived hash-pinned provider (slot 6/player `$08`,
  energy 397, seçim yok) ile viewport'ta üretildi ve aynı frame-8953 FCEUX panel
  bölgesiyle karşılaştırıldı. Odaklı harness, ROM IRQ'sunun sonraki CHR
  seçicilerini R0=`$00`/R1=`$02` kullanınca beklenen kırpımda 6.214/7.680
  piksel (%80,911) eşleşti; ortalama mutlak RGB kanal hatası 48,6758. Yalnız
  tanı amaçlı −8…+8 satır kayıt araması +6 satırda 7.680/7.680 tam eşleşme
  buldu. Bu, izole panel çizimini doğrular; canlı IRQ/viewport satır hizasını
  kanıtlamaz ve bu kaydırma runtime'a eklenmedi. Harness
  `tools/diagnostics/capture_compare_first_action_panel_component.gd`; test
  scroll'u `(0,0)`'da izole eder, dolayısıyla B→panel route/raster entegrasyonu
  veya tam ekran parity'si değildir. Görseller
  `/tmp/ct2_godot_first_action_panel_component_8953.png` ve
  `/tmp/ct2_first_action_panel_component_diff_8953.png`.
- İlk komut ekranı için ROM actor presenter'ı şimdi player-state ve
  caller-owned actor-context verildiğinde 41 ROM-derived sprite'ı aynı Godot
  görsel katmanına ekleyebiliyor; arka planın ortak palette rengini aktif ROM
  profilinden alıyor ve henüz desteklenmeyen özel palet dallarını reddediyor.
  Odaklı doğrulayıcı `tools/diagnostics/verify_first_command_visual_composition.gd`
  actor satırlarını endpoint RAM/PPU dökümlerini yalnız test fixture'ı olarak
  kullanarak kontrol etti: OAM 164/164 ve sprite paleti 16/16 byte eşleşti.
  Runtime bu dökümleri okumaz. `KickoffRouteRuntime` canlı
  `$0517/$0538/$0540/$0541` değerlerini hâlâ kaynak olaylarından üretip
  presenter'a vermediği için gerçek rotada actor görünümü ve katman önceliği
  açık; bu doğrulama tam ekran parity'si değildir. Yeni sessiz, aynı-girdili
  FCEUX izi frame-8399 anonim checkpoint'inden 8400–8953 aralığını iki kez
  oynattı ve 584 paylaşılan-state yazımını kaydetti; iki geçiş byte-byte
  eşleşti, checkpoint imzası iki yüklemede doğrulandı. İz `$0538`'in
  `$8814` bank-$18 yazarı tarafından 8461–8953 arasında her frame `$00`
  yazıldığını, `$0540/$0541` clip sınırlarının bank-$14 `$8053/$8058` sonrası
  PC'lerinde sekiz actor-engine başlangıcında sırasıyla `$00/$FF` yazıldığını
  gösteriyor. `$0517` için `$ED12` bank-$1F kopyaları da gözlendi; frame 8656'da
  `$052A=$40` değeri kopyalandı ve endpoint frame 8953'te `$0517=$40` kaldı.
  Bunlar doğrulama izleridir; endpoint RAM'i runtime'a girdi olmaz. Canlı
  holder/player state'i ve senaryo/task geçişleri hâlâ route'ta üretilmediği
  için bu değerlerin Godot sunumuna bağlanması açık. Kaydedilen PC/bank, kare,
  çevrim ve tekrar doğrulama ayrıntıları
  `reference/rom_extract/gameplay/first_command_actor_shared_render_state_trace_20261028.md`.
- Rota sesinde ROM kuyruğu tetikleri hâlâ eşleşmiyor: ROM-only kaynak izi ilk
  `$55` isteğini frame 4816'da cutscene `$ED` üzerinden, ikinciyi frame 7409'da
  doğrudan maç-kurulum `$812C/$812F` yazımıyla gösteriyor. Önceki Godot
  uygulamasının ikinci `$55` çağrısı MEETING menüsünün Başla onayına bağlıydı;
  bu yanlış tetik kaldırıldı. İlk `$55` hâlâ route tick 4773'te, `$53` ise
  8271 yerine 8113'te çalıyor; ROM görev yürütücüsü `$812C/$812F`'e ulaşmadığı
  için ikinci `$55` üretilmiyor. Cutscene `$ED` ses istekleri artık
  `RomSoundQueueWriteEvent` kimliğiyle, kaynak script adresi ve `$85EC/$85FC/$85FF`
  handler/store/post-store PC'leriyle taşınıyor; ancak route tick'i mutlak ROM
  karesi/CPU çevrimi değil ve `timing_verified=false`. Sabit bir bekleme/kare
  tablosu yerine gerçek kaynak çağrısını yürütmek gerekiyor. 28 Ekim
  aynı-input cue olayı denetimi ROM kaynak tablosundaki 10 beklenen ses
  başlat/durdur olayından 0'ını tam eşleştirdi; Godot'ta yalnızca 3 karşılık
  gelen olay vardı: `$55` başlat 4773, `$55` durdur ve `$53` başlat 8113.
  Beklenen olaylar 4816, 7243, 7409, 8108, 8271 ve 8443 karelerindedir; rotada
  `$3C/$66/$2B/$2C` olayları da üretilmedi.
  Denetim captured WAV/PCM yüklemedi ve üretim sesini değiştirmedi. Bu olay
  farkı, ROM ses verisinin Godot rotasında doğru kaynak noktalarında
  yürütülmediğini gösteriyor; sabit kare tablosuyla yamalanmamalı. ROM-driver
  WAV'i ROM verisinden üretilmiştir; aynı girdili FCEUX PCM ve tam rota cue/SFX
  eşliği hâlâ doğrulanmadı. Kanıt:
  `tools/diagnostics/audit_kickoff_route_audio_event_parity.gd`, rapor hash'i
  `342d980e416edde32c2858b671d42abd6eb5921b1029a04c6408e19d4949c298`,
  `reference/rom_extract/gameplay/first_match_audio_source.md` ve
  `first_match_audio_integration_audit_20261027.md`. Yeni ROM-source denetimi
  eksik ikinci `$55` çağrısının gerçek devamını belirledi: cutscene-1 dönüşü
  `$82B5`'ten `$80F1`'e gelmeli, `$8122-$812F` içindeki canlı `$26` dalını
  yürütmeli ve ancak `$812C` `$0700`'e yazarsa cue üretmeli; ardından
  `$8145-$815C` ID-2 seçim tablosu gelir. Muted iz `$A626` girişini ve ilgili
  APU yazılarını doğruluyor, fakat `$812C` PC kancasını içermiyor. Bu çağrı
  production rotada hâlâ yürütülmüyor. Ayrıntı:
  `reference/rom_extract/gameplay/first_match_audio_integration_boundary_20261028.md`.
- 28 Ekim temiz kopyası `/tmp/ct2-route-standalone-20261028-r1/` `.nes`,
  `.fm2/.fcs/.sav`, `reference/diagnostics/`, ekran görüntüleri ve eski intro
  capture dizini olmadan kuruldu; yalnız runtime için gereken
  `reference/rom_extract/`, `reference/palettes/` ve ROM-derived Godot WAV'leri
  korundu. Godot 4.7.2 resource import ve kısa main-scene açılışı geçti; kaynak
  handoff doğrulaması seçilmemiş `KICK OFF` title durumuna, route-wiring denetimi
  oradan cutscene ID 1'e ulaştı. Ayrı post-title route doğrulaması saha/menü-pending
  sınırına kadar çalıştı. Title cursor klavye/gamepad Down/Up/Select'i ve
  onaysız Start durumunu; ilk-menü input bileşeni başlangıçta seçim yokken
  klavye/gamepad yönleri ve A kapısını doğruladı. Typed ses-olayı provenance
  kontrolü de geçti. Bu kopyada emulator veya ROM
  yoktur; runtime bağımsızlığı title→route başlangıcı ve mevcut pending sınırına
  kadar gösterilmiştir, fakat canlı ilk komut menüsü henüz üretilmedi. Route hâlâ
  gerçek `$8327` task olayı ve önceki `$05CD` state'ini bekliyor; temiz kopya
  doğrulaması hedefi tamamlamaz. Görünür page-2 PPU karo farkı 452/512,
  `$36/$56` attribute eşleşmesi 32/32 ve 26/32 olarak kaldı.
- Route cutscene background ID'leri `$02,$04,$12,$13,$14,$15,$19,$2D,$5C,$5D,$5E`
  event bytecode'undan bulunup ROM kayıtları/metatile bloklarıyla çıkarıldı.
  Frame 8953 PPU arka plan paleti ROM palette `$02` ile byte-byte eşleşiyor.
  Önceki 408/512 arka plan karşılaştırması yeni selector-doğru `$36/$56`
  yerleşimiyle geçersiz kaldı. Güncel live route endpoint ölçümü görünür
  sayfa-2 karo kimliklerinde 452/512, map `$36/$56` özniteliklerinde 32/32 ve
  26/32 eşleşme veriyor. ROM `$F015/$F114` paketleri bu fark bölgesinin 60
  temel karosundan 59'unu ve altı öznitelik baytının tamamını üretiyor;
  `$F0B5` sonradan holder hücresine `$A2` yazıyor. `$8327` placement geçişi ve
  `$EFFC` descriptor seçimi ROM kodundan ayrı yardımcılarla çözüldü ve FCEUX
  iki-pass kayıtlarıyla doğrulandı. `FirstMatchFieldCandidatePresenter` artık
  callback anındaki `$0621/$0600/önceki $05CD` ile `$063D` ve `$05CE` değerlerini
  ROM yordamlarından türetip 60 tile + altı attribute paketini uyguluyor; sabit
  descriptor/placement değerleri ve endpoint RAM/PPU verisi kabul edilmez.
  Odaklı source-context verifier bu data path'i geçti. `KickoffRouteRuntime`
  ise gerçek `$8327` callback/task olayı ve önceki `$05CD` değerini henüz
  üretmediği için packet layer'ı çağırmıyor; live route ölçümü 452/512 karo ve
  map `$56` attribute'larında 26/32 olarak kalıyor. `$F0B5` holder write'ı için
  gereken canlı `$0635/$0637` actor state'i de açık. Tam saha rasteri, route-time
  oyuncu/OAM üreticisi ve canlı maç durumu hâlâ çözülüyor.
- İlk action-menu handler'ı hedef ROM'dan statik olarak çözüldü: taze left-team
  context `$0621=0` ile `$061E=0` başlar (eylem seçili değil); yeni Right/Left/
  Down/Up basımları sırasıyla Şut/Pas/Verkaç/Çalım seçer; A yalnız seçimden sonra
  onaylar. Yönler satır imlecini gezdirmez. Ayrıntı
  `first_action_menu_input_rom_trace_20261027.md` içinde; Godot menü seçimi
  route'a bağlandı, aynı girişte FCEUX D-pad/piksel karşılaştırması açık.
- KICK OFF animasyon ihracı 16 benzersiz ROM kaydını byte-byte doğruladı; 17
  çağrı ve 12 sprite kare grafiği çıkarıldı. Beş animasyondaki `$FA` dalları,
  bazı süreler, tam çizim/OAM, CHR/palet eşlemesi çözülmedi. Bak:
  `kickoff_animation_asset_map.md`.
- `$55` maç cue'sunda ROM-only NSF/libgme render'ı FCEUX PCM ile zayıf
  eşleşiyor. Tanılama amaçlı ROM-stepper/WaveHi adayı, ilk DMC faz
  çakışmalarının çevresine ROM kaynaklı bit-edge/buffer-load durum olayları
  eklenince 54 çakışmayı sıfırladı; aynı-girdi iki cue penceresinin
  korelasyonu yalnızca `0.847626 / 0.841291` oldu ve tam örnek eşitliği
  `%0.0341 / %0.0277` kaldı. Aday FCEUX kaydından 734 örnek kısa; kaynak
  adımlayıcısındaki instruction-hook/DMA sırası hâlâ gerçek donanım zamanlaması
  olarak doğrulanmadı. Bu WaveHi WAV'i tanılama çıktısıdır; runtime WAV,
  manifest ve route sesleri değiştirilmedi. PCM eşliği, başlangıç fazı, stop
  kuyruğu ve route SFX karışımı açık. Bak:
  `first_match_audio_integration_audit_20261027.md`.
- ROM'dan üretilen `$55` WAV'in 3.065 başlangıç sıfırı artık runtime'da ayıklanıp
  ilk iki queue oluşumuna source-stepper'dan türetilen 807/1.239 sessiz örnek
  ekleniyor. Godot bunu yalnızca hash-doğrulanmış ROM WAV'i ve ROM-stepper
  zamanlama yan dosyasından bellekte kuruyor; FCEUX PCM runtime girdisi değil.
  Aynı-girdi FCEUX pencerelerinde RMSE ilk kullanımda 5247,739→4732,145, tekrar
  başlangıcında 4665,947→4368,109 oldu; korelasyon 0,054655 / 0,246654'e çıktı.
  Tam eşleşen örnek sayısı 174→237 ve 58→27 değişti; korelasyon hâlâ düşük.
  Bu, ölçülmüş başlangıç hizalaması iyileşmesidir; PCM eşliği değildir.
  `verify_rom_cue_audio_presenter.gd` 14 ROM cue'su ve iki `$55` örneğini geçti.
  Godot ses sunucusunun FCEUX'e karşı tam rota çıktısı, PCM/DMC/filter ve SFX
  karışımı hâlâ açık. Ayrıntılar
  `reference/diagnostics/audio/route_cue55_asset_onset_audit_20261027.md` ve
  `reference/diagnostics/audio/route_cue55_onset_candidate_20261027/`.
- 28 Ekim Godot AudioServer karşılaştırması, üretim `$55` presenter'ının beş
  saniyelik çıktısının ROM/NSF'den üretilen WAV PCM'iyle normalize edilmiş
  hizalamada 219.627/219.627 örnek byte-eşit olduğunu gösterdi (`r=1`, RMSE 0).
  Aynı sinyal FCEUX referansıyla hâlâ zayıf eşleşiyor (`r=-0,250135` queue
  hizasında, `0,380653` ilk duyulur örneğe hizalandığında). Ölçülen waveform
  farkı Godot mixer'ında değil, libgme ROM/NSF üretimi ile FCEUX APU/WaveHi/
  mixer çıktısı arasındadır; alttaki APU, faz, mixer ve filtre nedeni henüz
  ayrıştırılmadı. Capture'a özgü Godot ilk-örnek gecikmesi 66 örnektir;
  üretim timing'i bu ölçüme dayanarak değiştirilmedi. Karşılaştırma tam rota
  veya fiziksel NES eşliği değildir. Ayrıntı
  `reference/rom_extract/gameplay/first_match_audio_source.md` içinde.
  Soğuk ROM başlatımındaki `$4017=$40` yazısını tek başına eklemek de FCEUX
  benzerliğini iyileştirmedi; bu aday üretime alınmadı. Tam rota WaveHi adayı
  daha iyi korelasyon gösterse de APU geçmişi, DMC ve filtreyi birlikte
  değiştirir ve source parity olarak doğrulanmış değildir.
  Ek tanı denemesinde ROM-only tüm DMC bit-edge/buffer satırlarını WAV'e
  uygulamak da reddedildi: 1.848.230 satırlık aday iki `$55` FCEUX penceresinin
  korelasyonunu 0,847443→0,805107 ve 0,841283→0,806594 düşürdü; RMSE yükseldi.
  Üretim sesi değişmedi. Yöntem, hash ve yeniden üretim komutları
  `first_match_audio_integration_audit_20261027.md` içindedir.
- ROM bank `$0C:$86A3` ilk `$55` setup'ında `$4010/$4012/$4013/$4015` yazıyor,
  `$4011` DAC latch'ini yazmıyor. Stop `$01` ile ilk `$55` arasında kaynak izi
  `$4011` yazısı göstermiyor; FCEUX-compatible model latch'i `$60`'ta korurken
  bağımsız libgme track reset'i DAC'ı sıfırlıyor. Offline NSF'de `$4011=$60`
  seed denemesi, 1.780.856 örnekli source-start hizasında korelasyonu
  `-0,171442→-0,171785` yaptı; RMSE `5247,739→5247,469`, eşleşen örnek
  `174→190` oldu. Bu küçük fark eşliği düzeltmedi; first-nonzero trim daha da
  kötüleşti. Başlangıç durumu farkı gerçek ama ses farkının açıklaması değil.
  Üretim PCM değişmedi. 28 Ekim sessiz driver-event karşılaştırmasında tekli
  `$55` NSF, ilk 176 per-register yazı değerinde pulse-2 `$4006`'nın ilk 40
  yazısı (`+$EF mod 256`) ve ilk `$4007` (`$18` yerine route `$98`) dışında
  FCEUX ile eşleşti. ROM-only önceki 14 queue olayını aynı sürücüden geçirince
  176 karşılaştırmalı yazının tamamı FCEUX APU iziyle ve ilk 1.285 DMC örnek
  byte/adres çifti ROM-source rota DMC önekiyle eşleşti. Böylece tek-cue wrapper'ın ilk pulse-2 için
  gereken ses sürücüsü geçmişini atladığı doğrulandı; tek bir RAM değerini
  varsaymak yerine önceki ROM olaylarını yürütmek kaynakla uyumlu durum
  kurulumudur. İlk `$4000` olayına göre 176 güncellemede zaman artığı tekli
  NSF'de -231…+21, geçmiş NSF'sinde -259…0 CPU çevriminde kaldı; büyüyen kare
  kayması görülmedi. Geçmiş NSF'nin mutlak başlangıcı 63.059 çevrim erken;
  wrapper route scheduler'ını yürütmediği için bu üretim zamanlaması değildir.
  Uzun PCM penceresindeki kalan farkın APU/2A03 evrimi, DMC faz/arbitrajı,
  WaveHi miksleme, yeniden örnekleme veya filtre kaynaklarından hangisi olduğu
  hâlâ ayrıştırılmadı. Üretim WAV/timing/runtime değişmedi. Ölçümler,
  komutlar ve izler `reference/rom_extract/audio/first_match_bgm55_driver_trace_20261028/`
  ile `reference/rom_extract/gameplay/first_match_audio_source.md` içinde.
- Kaynak-yalnız CPU stepper izi için `tools/audio/export_first_match_cue_timing.py`
  tekrarlanabilir kuyruk→APU zamanlaması dışa aktarımı ve
  `reference/rom_extract/gameplay/first_match_cue_timing_rom_stepper_20261027.json`
  referans çıktısı eklendi. İki `$55` kuyruğundan ilk `$4000` yazısına sırasıyla
  32.762 ve 50.291 CPU çevrimi var; bu, ilk duyulur örneği veya PCM eşliğini
  kanıtlamıyor. `rom_cue_audio_presenter.gd` bu ROM kaynaklı gecikme metadata'sını
  ilk iki `$55` oluşumunda kullanıyor; bu, tanılama amaçlı WaveHi PCM adayının
  runtime'a alındığı anlamına gelmiyor. Ayrıntı
  `reference/rom_extract/gameplay/first_match_audio_source.md` içinde.
- KICK OFF seçimi açılış presenter'ından route sahnesine bağlı. Cutscene VM,
  ROM komut verisinden ID 1/2'yi ve sahne `$44`'ü çalıştırıyor; ROM cue
  presenter'ı da paketlenmiş ROM-derived cue'ları dispatch ediyor. Yeni
  `verify_kickoff_recorded_input_path.gd`, yakalanmış tuş kenarlarını aynı
  kaynak karelerinde uygular: ID 1 → eşleşme kartı → `$44`/`MEETING` → ID 2 →
  başlama geçidi → saha → B ile ilk panel isteği. Aşamalar frame 7243, 7393,
  7993, 8443, 8593, 8743, 8893 ve 8953'te kaydedilen referans girdi sırasını
  izliyor. İlk panel isteği kare 8953'te geliyor; bu davranış yolu kontrolüdür,
  görsel/ses eşliği kanıtı değildir.
  Godot şu an sahne `$44`/ID 2'nin son arka planını 8743–8863 boyunca tutuyor;
  FCEUX görüntülerinde ise 8743'te hâlâ anlatım/karakter, 8788–8863'te enerji
  durum ekranı var. Saha adayını 8743 Select'inde göstermek erkendi; presenter
  çağrısı 8893 B kenarına taşındı. Bu yalnız geçiş anını hizalar, doğru saha
  katmanını veya aradaki anlatım görsellerini henüz sağlamaz.
- 28 Ekim görsel boşluk denetimi, bu geçişin eksik kısmını netleştirdi: FCEUX'te
  frame 8743'te narration/field/score/dialogue görünür, 8788'de oyuncu ve top
  animasyonu sürer, 8863'te formation/radar ve 397 enerji satırı görünür; B
  frame 8893'te gelir ve tam komut paneli frame 8953'e kadar görünür olur.
  Bunlar doğrulama örnekleridir, çalışma-zamanı kare sabitleri değildir. ROM
  yolu ayrı bank-$10 `$35/$36/$1E` senaryolarını, bank-$14 animasyon
  worker'larını ve bank-$16 descriptor/OAM üretimini kullanır. Godot şu an
  Select'te cutscene VM'yi durdurup kaba saha aşamasına geçiyor, bu worker'ları
  çalıştırmıyor ve saha adayını ancak B'de kuruyor; dolayısıyla anlatım→oyuncu
  hareketi→formation/enerji ara görüntüleri eksik. Ayrıntı ve kaynak sınırı
  `reference/rom_extract/gameplay/kickoff_field_intro_visual_gap_20261028.md`.
- İlk komut paneli ROM descriptor/text verisi ve canlı eşleşme durumu için
  çözücüyle hazır. Panelin route API'si, başlangıçta seçimsiz durumu, Right →
  Şut seçimini ve ROM'un 13-tick etiket blink fazını Godot entegrasyon
  denetiminde geçti. `rom_fresh_kickoff_match_state_provider.gd` 11 oyuncunun
  başlangıç kayıtlarını ROM roster/stat/stamina/pointer tablolarından kuruyor;
  slot 6 / oyuncu 8 için level 0 ve maksimum enerji 400 kaynak baytlarından
  hesaplanıyor. On bir uygun saha döngüsü adımında 3 enerji bedeli, 256
  `$0618` adımında takım yenilenmesinin atlanması da tanılamada geçti. Ancak
  `KickoffRouteRuntime` artık doğrulanmış sağlayıcıyı bağlama, panel durumunu
  sağlayıcıdan kurma ve caller'ın ROM `$E14D` kontrolüne ulaştığını bildirdiği
  saha döngüsü adımlarını iletme API'sine sahip. Odaklı Godot denetimi artık
  receiver'ı hash'li ROM-stepper rotasından, oyuncu/enerji verisini ROM
  tablolarından kurup paneli yakalanmış RAM kullanmadan çiziyor; Right→Şut ve
  13-tick blink de geçti. Buna rağmen production rota bu API'yi çağırmıyor:
  receiver RNG'si tek hash'li kayıtlı girdiye bağlı ve canlı rota `$E14D` uygun
  döngü olaylarını üretmiyor. Bu nedenle ilk menüye kadar otomatik, aynı-input
  canlı rota doğrulanmış değil. Hiçbir futbol aksiyonu onaylanmadı.
- 28 Ekim doğrulaması: ROM-stepper girdi zaman çizelgesi, yalnızca test amaçlı
  input CSV içeren temiz kopyada Godot'a verildi; `.nes` ve FCEUX olmadan rota
  frame 8953'te kaynak callback'i bekleyen `pending` sınırına ulaştı, komut
  menüsü oluşturulmadı. Bu rota aşamalarını ve runtime bağımsızlığını doğrular,
  panelin aynı-girdi piksellerini değil. Menü
  kontrolleri için ayrı test başlangıçta seçimsiz durumu, klavye/kol yön
  eşlemesini ve A onay kapısını geçti; route entegrasyon testi de ROM-derived
  oyuncu verisiyle Right→Şut ve 13 modeled tick blink davranışını geçti.
  Godot 4.7.2 temiz kopyası `.nes` ve FCEUX olmadan ROM-derived proje
  kaynaklarıyla import edilip kısa süre başlatıldı. Bu, ROM'suz çalışma
  bağımsızlığını doğrular; maç route görsel/ses eşliğini doğrulamaz. Son temiz
  kopya import ve kısa başlatmayı hata/uyarı olmadan tamamladı.
- RNG'nin ROM aritmetiği ayrı, tipli Godot yardımcısına taşındı: `$A116`'daki
  `CLC` ve `$A117`'de başlayan güncelleme ile `$C9C5` indexed dönüşümü ROM
  komut baytlarından 729 ve 1.620 durumla karşılaştırıldı; korunan iki kaynak
  spanı ROM hash'i/offset'iyle doğrulandı. `$C9C5` açık carry ve 2 KiB iç RAM
  alıyor; `$0780,X` aynalaması uygulanıyor. Bu yalnız aritmetik bileşeni:
  çağrı seçimi, `$001B.6`, controller polling'i, canlı `$0300/$0700/$0780`
  operand üretimi ve receiver dispatch'i yok. Hash'e bağlı RNG tekrarını
  üretime bağlamıyor. Ayrıntı
  `reference/rom_extract/gameplay/kickoff_rng_arithmetic_component_20261028.md`.
- 28 Ekim statik source audit'i, bank-$02 `$A484` tablosunda `$00ED` indeks
  8/9'un `$001B.6` bitini temizleyip kurduğu olası yolu buldu; üç doğrulanmış
  KICK OFF bytecode akışında `$F8` yok ve bu indekslerin rotada çalıştığı
  kanıtlanmadı. `$C41E→$A200→$A21B` de olası bir bit-set yolu, fakat çağıran
  route zinciri bilinmiyor. İlk `$C9C5` çağrısından önce `$0300/$0700/$0780`
  yazıcılarının canlı geçmişi de yok; bu yüzden tek hash'li RNG kaydı genele
  çevrilmedi. Ayrıntı `reference/rom_extract/gameplay/first_command_rng_pre8400_static_audit_20261028.md`.
- Aynı 8399 checkpoint'inden alınmış sessiz PPU bus izi, descriptor `$02`
  commitlerini 8937–8939'da, `$03` commitlerini 8940–8945'te ölçüyor;
  genişletilmiş PC/queue izi de renderer çağrılarını, dokuz queue çevrimini ve
  B→ilk queue aralığını doğruluyor. Son nametable paketi B'den 52 kaynak kare
  sonra commit ediliyor; ilk görünür pikselin zamanı bilinmiyor. Bunlar
  diagnostic trace ölçümleridir. Godot'taki sabit 60-tick fallback kaldırıldı;
  route şimdi gerçek kaynak callback'i gelene kadar pending kalıyor. Ayrıntılar
  `reference/rom_extract/gameplay/menus/first_action_menu/menu_renderer_algorithm_audit.md`
  ve `first_command_menu_wait_and_stamina_trace_20261028.md` içinde.
- Saha adayı artık ROM selector tablosuyla hem animasyon `$45`/map `$36`
  (selector `$01`, bank `$12`) hem `$70`/map `$56` (selector `$02`, bank
  `$13`) kaynaklarını açıyor. ROM `$85C2` adres hesabına göre tile başlangıçları
  `$2800/$2A00`, öznitelik başlangıçları `$2BC0/$2BE0`; byte'lar ve SHA-256'lar
  `reference/rom_extract/gameplay/first_command_field/page_correct_map_sources/`
  altında korunuyor. Runtime hiçbir PPU yakalama baytını tüketmiyor.
- Güncel `verify_kickoff_route_to_first_menu.gd` rota denetimi geçti. Frame-8953
  PPU nametable ile aynı-girdi kaynak karşılaştırması görünür page-2 satırları
  14–29'da **452/512 tile ID**, map `$36` özniteliklerinde **32/32**, map `$56`
  özniteliklerinde **26/32** eşleşme verdi. Kalan 60 karo ve altı öznitelik aynı
  10×6 bölgede. `$F015/$F114` decoder'ı ROM baytlarından altı paket oluşturuyor;
  bunlar FCEUX buffer prefix'leriyle byte-byte eşleşti, temel 60 tile'ın 59'u
  ve altı attribute byte'ının tümü endpoint PPU oracle'ıyla eşleşti. Tek tile
  farkı `$2AE6` adresinde `$F0B5`'in sonradan yazdığı `$A2`; ayrı holder hesabı
  bunu aynı trace kaynak girdileriyle üretiyor. Kaynak paket ve endpoint PPU
  karşılaştırmasının ayrıntısı `first_command_field_packet_producer_20261028.md`
  içindedir.
- Yeni muted FCEUX iki-pass trace, 8399 anonymous checkpoint'inden sonra
  8400–8953 aralığını tekrar oynattı. Checkpoint frame/cycle, 2 KiB RAM, 16 KiB
  PPU memory ve MMC3/PRG imzasıyla her yüklemede doğrulandı; iki normalize geçiş
  eşit. `$F015` bank `$1F` kare 8908–8913'te altı kez giriyor; her girişte
  `$063D=$02`, `$05CE=$A0`, `$05CD=$80`, A `$00…$05`. `$05CE`'nin son yazarı
  kare 8905 cycle offset 22035'te bank `$0B:$8342` (trace post-PC `$8345`) olup
  `$A0` yazar; takip eden `$0B:$8349` `$05CD=$80` yapar. `$063D` kare 8908'de
  önce `$1F:$EFFC`'de `$00`, ardından `$1F:$F009`'da `$02` olur. Taze B/menu
  akışının `$0621=0/$0600=0` girdileri selector formülünü kaynak mantığıyla
  açıklar. `$F0B5` kare 8915'te `$0635/$0637=$7C/$AC` ile girer.
- `$0635/$0637`, `$E6F2/$E6FA`'da `$0034`'ün seçtiği dinamik kaydın ofset 6/8
  alanlarından kopyalanır. `$CD7C` pointer yordamı çözüldü: `ASL A; TAY; LDA
  $CD89,Y; STA $34; LDA $CD8A,Y; STA $35`; `$CD89` tablosu 22 kaydı `$0300`'dan
  başlayıp `$0C` adımla seçer. `$DC63/$DC68` koordinat RAM kayıtlarını yazar;
  aktif-player record seçiminin route caller zinciri henüz Godot'a taşınmadı.
  `RomFirstCommandHolderCoordinateResolver`, `$E0F6→$E6EC→$CD7C/$CD89`
  kopyasını ROM baytlarından doğrulayıp yalnızca açıkça verilmiş bir holder slotu
  için başlangıç kaydının `+$06/+$08` değerlerini çözüyor; 22 slotun tamamı
  denetlendi ve slot 6 kaynak verisi `$7C/$AC` verdi. Yardımcı holder slotunu
  seçmiyor, hareketi veya callback state'ini üretmiyor ve canlı rotaya bağlı
  değil. Ayrıntı `reference/rom_extract/gameplay/first_command_holder_coordinate_resolver_20261028.md`.
  `$8327`'nin `$05CD→$05CE/$05CD` ROM geçişi producer sınıfına taşındı ve sekiz
  FCEUX callback state'iyle iki-pass doğrulandı; ancak production route bu
  transition'ı `$70` map callback'inden çağırmıyor. `$063D` selector resolver'ı
  da var, fakat route henüz `$0621/$0600` source state'ini presenter'a iletmiyor.
  Bu nedenle holder overlay ve 60+6 residual hâlâ production presenter'da
  uygulanmıyor. Runtime endpoint RAM/PPU capture kullanmıyor.
- İz ve decoder kanıtları `reference/diagnostics/first_command_field_producer_input_trace_20261028_053644_utc/`
  ve `reference/rom_extract/gameplay/first_command_field_05ce_source_xref_20261028.md`
  içinde. Önceki `$06CE` izlemesi yanlıştı ve yeni `$05CE` writer trace'iyle
  geçersiz kaldı. Eski `$2BC0` 32/32 eşitliği de `$56` map yerleşimini
  kanıtlamıyordu. Kaynakta bir sonraki entegrasyon noktası senaryo `$44`
  olay `$70/$5C` (`0x0237E5`, `02 70 5C F0`) ve bank `$0B:$8B38` map callback'idir;
  trace dispatch'i frame 8893'te, son placement yazımını frame 8905'te ölçtü.
  Godot bu kayıt callback'ini çalıştırıp `$8327` transition helper'ını
  çağırmalı; gözlenen frame veya `$A0` sabitini atamamalı.
- 28 Ekim sessiz FCEUX iki-pass izlemesi artık bu callback'in asenkron sınırını
  netleştiriyor: `$814C → $81A7 → $8327` içinden çağrılan `$8525`, `$C515 →
  $CB0F` işçi scheduler'ında bekleyip döndükten sonra `$05CE/$05CD` yazar.
  Frame 8893 dispatch'i ve frame 8905 yazımı iki geçişte eşleşti; önceki
  `$05CD=$A0` callback argümanı değil, önceki `$35/$36/$1E` akışlarındaki ROM
  callback/worker geçmişinin ortak RAM çıktısı. Bu nedenle sabit `$A0` veya
  yalnız gecikme sayan scheduler runtime'a alınmadı. İki 20.052 olay/51.562
  RAM-yazım izinin karşılaştırması 13,981 saniyede eşleşti. Trace ve source
  sınırları `reference/rom_extract/gameplay/first_command_callback_scheduler_trace_20261028.md`
  ve `reference/diagnostics/first_command_callback_state_20261028_061906_utc/`
  içinde; gerçek task-slot/continuation state'i Godot'a hâlâ bağlanmadı.
  Yeni diagnostic-only prefix modeli, scenario `$44` root `$FB` → callback
  `$70` offsets `0/1/2` → `$8327` başlangıcını ve açık A değeriyle `$F015`
  `0..5` artış döngüsünü doğruluyor; incoming `$05CD`, `$F015` çağrısının
  nedensel bağlantısı ve giriş A'sı hâlâ üretilmiyor. Ayrıntı
  `reference/rom_extract/gameplay/first_command_callback_prefix_model_20261028.md`.
- 28 Ekim ek task-boundary izi, sabit scheduler'ın altı slotu `$0001/$0005/
  $0009/$000D/$0011/$0015` sırasıyla taradığını; her slotun dört baytında
  hazır/gecikme değeri, saved SP ve bank bağlamı bulunduğunu, gerçek dönüş
  adresi/devam durumunun 6502 stack sayfasında yaşadığını doğruladı. Yeni `$15`
  görevi `$C50F/$CAE7` ile hazırlanıp `$814C` callback'ine giriyor; `$8525`
  `$C515/$CB0F` üzerinden yield edip stack/bank/SP bağlamıyla sürüyor ve
  `$CAF7` ile temizleniyor. `$ED15/$ED2D` ayrı `$0011` bank-$18 işçisini kuruyor;
  bu, `$EE9F → bank-$14:$800F` saha-aktör döngüsüyle aynı şey değil. İkincisi
  kare 8461–8953 arasında kare başına bir kez, toplam 493 kez gözlendi. İki-pass
  trace frame-8399 anonim checkpoint'ini her yüklemede RAM/PPU/MMC3/PRG imzasıyla
  doğruladı ve her geçişte 6.081 event/62.357 write üretti; normalize event ve
  write hash'leri eşleşti. İlk warmup denemesi frame 0 öncesinde 60 saniye
  ilerleme sınırında atıldı ve checkpoint üretmedi; başarılı tek FCEUX oturumu
  bir anonim state'i iki geçişte kullandı. Bu kanıt scheduler'ı Godot'a
  bağlamıyor: stack-backed continuation, bank/SP, NMI latch'i ve ayrı
  parser/worker context'leri modellenmeden süre sayacı yeterli değildir.
  Ayrı diagnostic-only model, `$C50F/$CAE7` seed, `$CB0F` yield-save, bir
  finite-delay resume ve `$CAF7` finish işlemlerini ROM baytlarıyla doğruluyor;
  FCEUX trace'i sadece bağımsız karşılaştırma oracle'ı. Yeni ayrı scan modeli
  altı-slot sırasını, gecikme kararını ve `$001B.7` gate'ini de byte/trace
  düzeyinde doğruluyor; NMI cadence'i, tam task yaşam döngüsü, önceki callback
  geçmişi ve runtime entegrasyonu hâlâ yok.
  Trace ve kaynak sınırı `reference/rom_extract/gameplay/first_command_task_boundary_trace_20261028.md`
  ile `reference/diagnostics/first_command_task_boundary_20261028_070655_utc/`
  içinde. Model/verifier: `tools/diagnostics/rom_gameplay_task_context_model.gd`,
  `tools/diagnostics/verify_rom_gameplay_task_context_model.gd`; scan
  modeli/verifier/notu `tools/diagnostics/rom_gameplay_scheduler_scan_model.gd`,
  `tools/diagnostics/verify_rom_gameplay_scheduler_scan_model.gd` ve
  `reference/rom_extract/gameplay/fixed_task_scheduler_scan_audit_20261028.md`.
- 28 Ekim source-model takibi ilk `$CA97` taramasındaki slot `$0001` engelini
  ROM kaynaklı olarak kapattı: cold-RAM zero-fill, `$C6BE–$C6E7` slot temizliği
  ve `$C6E8–$C765` bootstrap slot `$01/$05/$09` kayıtlarını ve `$CA21/$D11D/
  $EB85` stack devamlarını kuruyor; ilk tarama `$01`'i seçiyor. `$001B.7`
  normal/bank-$02 ready yolları ve NMI mode gate'i hash-korumalı kaynak
  spanlarıyla modellenip frame-8460 iki-pass iziyle doğrulandı.
  `tools/diagnostics/verify_rom_gameplay_root_task_bootstrap.gd` geçti. Bu,
  root task gövdelerini, NMI edge cadence'ini veya production scheduler'ı
  çalıştırmıyor; sonraki gerçek eksik hâlâ task continuation'larının
  scenario/callback geçmişini ve `$05CD`'yi üretmesi. Ayrıntı
  `reference/rom_extract/gameplay/first_command_root_task_bootstrap_and_nmi_20261028.md`
  ve `first_command_live_route_composition_boundary_20261028.md`.
- Güncel Godot rotası, B girdisinden sonra ilk action-menu `pending` aşamasında
  kalıyor; eski 60 tick'lik placeholder wait kaldırıldı. Tek-slot task-context,
  root-task bootstrap/NMI ve altı-slot scan modelleri tanısal parçalardır; root
  task gövdelerini, NMI edge cadence'ini, parser continuation'ını veya callback
  geçmişi/ortak `$05CD` state'ini production route'ta üretmez. En küçük eksik
  zincir: bank-$10 parser continuation → `$0015`
  callback task'inin altı-slot scheduler'da resume edilmesi → `$814C/$81A7`
  dispatch'inin `$8327` handler event'ini ve A alt-indekslerini üretmesi → önceki
  `$05CD` state'inin callbacks boyunca korunması. Bu producer olmadan packet
  layer/ilk menü live route'a bağlanmadı. `verify_kickoff_route_to_first_menu.gd`
  eski 60-tick aralığını aşınca route'un pending kaldığını doğruluyor; kayıtlı
  aynı-input denemesi frame 8953'te aynı sınırda duruyor. Source-context yolu:
  `tools/diagnostics/verify_first_command_field_source_context.gd`.
- Bank `$1F:$EFFC` `$063D` selector'ı artık hash-korumalı ROM code/table
  baytlarını kullanan ayrı `RomFirstCommandFieldDescriptorResolver` ile
  modelleniyor. Odaklı Godot 4.7.2 doğrulaması taze rota `(context=0,
  defender_count=0) -> $02`, komşu context `$01 -> $00` ve context `$00` ile
  nonzero defenders `$00` sonuçlarını doğruladı. Bu yalnız selector kuralı;
  `KickoffRouteRuntime` henüz `$0621/$0600` source state'ini taşımıyor ve
  presenter'a bağlanmadı. UI window descriptor `$02` ile field packet
  descriptor `$02` aynı kavram değildir. Kaynak ve sınırlar
  `reference/rom_extract/gameplay/first_command_field_descriptor_063d_source_audit_20261028.md`
  içinde.
- `$DC07` başlangıç konum üreticisi ROM code/table baytlarından ayrı helper'a
  taşındı. Dört formasyon satırı × 11 oyuncu stride'ı, `$CD89` 22 record
  pointer'ı ve `$CDC9` koordinat dönüşümü doğrulandı; slot 6'nın koordinatı
  helper içinde kaynak tablosundan hesaplanıp yalnızca diagnostic RAM oracle'ı
  ile karşılaştırılıyor. Yeni byte-level `$0629` source audit'i, taze KICK OFF
  akışının selector 0'ı `$A2AF→$AA06` clear ve `$D11E→$D14F` period write
  üzerinden ürettiğini doğruladı; bu selector `$DB34` match-0 dalına gider.
  `$DB34` ayrıca match-0 home/away formation 0 ve `$05FB=0` possession'ı
  kuruyor. `KickoffRouteRuntime` artık kickoff kapısında bu ROM kaynaklı
  bağlamı çözüp 22 başlangıç koordinatını saklıyor; route denetimi geçişi,
  match-0 değerlerini ve slot-6 pointer/table eşleşmesini doğruluyor. Bunlar
  oyuncu sprite'larını çizmez veya hareket ettirmez. Aktif receiver, sonraki
  oyuncu hareketleri ve actor cadence'i hâlâ production state değil.
  Ayrıntı
  `reference/rom_extract/gameplay/first_command_field/player_record_positions/source_audit.md`.
- 8399 in-memory checkpoint'inden alınan genişletilmiş, sessiz FCEUX izi iki replay'i byte-byte eşleştirdi (7.027 event ve 78.847 RAM yazımı/pass; 18,888 s). `$E145/$E14D` pencerelerini doğrulamanın yanında `$E1F7→$E2BC`'yi bir kez frame 8858'de gördü; `$0618` aynı çağrıda `$00→$01→$00` oldu. İkinci `$0614` sıfırına frame 8892'de ulaşıldı; B frame 8893'te geldiği için ikinci stamina çağrısı yok. Menü tarafında `$D575` frame 8908, `$D5C3` frame 8926, bank-$18 `$8852` descriptor `$02/$03` için 8935/8938'de; ilk queue satırı frame 8936'da. `$0515/$05C5/$05C6` dokuz queue çevrimini 8936–8944'te gösteriyor: `$02` için üç, `$03` için altı. Bu 8893 B → 8936 ilk row queue aralığı 44 kapsayıcı kaynak karedir; ilk görünür pikseli veya başka bir input yolunun genel gecikmesini kanıtlamaz. Player-stat RAM yazıcıları izlenmedi ve 8856–8881 `$E145` boşluğu route entegrasyonuna hâlâ açık. İz/method `reference/rom_extract/gameplay/first_command_menu_wait_and_stamina_trace_20261028.md`; önceki geniş actor/scheduler dökümü `first_command_combined_state_trace_20261028.md` içinde.
- Bank `$10` scenario `$44` için pointer-bounded ROM stream'i `02 70 5C F0 FB`.
  Reader `$0524=$70` callback'ini, `$0528=$5C` actor animasyonunu ve
  `$0529=$FF` parametresini çözer. Yeni `$FA/$FB` modeli dört doğrulanmış rota
  stream'inin depth-zero `$FB` bitişini ROM `$80CF` root-terminal yolu olarak
  sınıflandırır; senaryo `$44` callback API'si bunu açık depth=0 girdisiyle
  kullanır. Bu, bank-$05 dialogue cutscene VM ID `$44`'ten farklıdır ve kendi
  başına `$70` callback'ini üretmez. Helper iç içe `$FA/$FB` LIFO işlemlerini
  explicit stack baytlarıyla hesaplayabilir; ancak route'ta canlı continuation
  state'i, outer CPU/task return, worker/scheduler akışı ve önceki `$05CD`
  state'i hâlâ modellenmedi. Godot 4.7.2'de continuation-stack, scenario reader
  ve `$44` callback verifier'ları geçti; bunlar source parsing/transition
  sınırını doğrular, canlı route entegrasyonunu değil;
  ayrıntı `first_command_scenario_stack_continuation_source_20261028.md` ve
  `first_command_scenario_44_runtime_boundary_20261028.md`.
- ROM kaynaklı `$01` arka plan paketleriyle yapılan ayrı adres kapsamı probu,
  bu 60 artık hücreye hiç yazmadığını gösterdi (0/60 adres örtüşmesi). Bu nedenle
  farkı `$01` baytlarıyla örtmek için kaynak dayanağı yok. Yeniden üretilebilir
  sorgu `tools/diagnostics/probe_first_command_field_residual_layers.gd`.
- Yeni ROM harita taraması, 132 tam metatile haritasının hiçbirinin aynı 60 karo
  ve altı öznitelik farkını tek başına açıklamadığını doğruladı. `$70/$56`
  yolundaki kalan kompozisyon/PPU paket sırası hâlâ bulunmadı. `$70` opcode
  `$06` → `$83D2` → `$8386` → `$8393/$84A1(A=$A0)` yolu byte-check ile doğrulandı;
  bu, ilk PPU görünümünü page 2 / scroll `$74` olarak Godot adayına taşıdı.
  Kaynak `$C8F7` tablosu ve NMI/IRQ kodu ayrıca `$7B` MMC3 latch'i, IRQ enable ve
  IRQ'da `$2006=$2200`, scroll 0 ile CHR yenileme yolunu doğruluyordu. Yeni
  sessiz, aynı-girdili FCEUX izi frame 8953'te `$C821` IRQ girişini kare başından
  16.360 CPU çevriminde, `$C852`'yi 16.409'da ve `$2006=$2200` yazılarını
  16.462/16.468'de ölçtü; `$2000=$8A` 16.477'de, `$2005=0,0` ise
  16.487/16.491'de yazıldı. Ardından geçici, kaynakla eşleşen FCEUX 2.7.0 NewPPU
  yapısında aynı girdiyle tekrarlandı: `$C821` line 123/dot 312; `$2006=$22/$00`
  line 124/dot 274/292; `$2000=$8A` line 124/dot 320; `$2005=0,0` line 125/dot
  8/20. Böylece FCEUX modelindeki IRQ ve register yazım rasterı biliniyor; ilk
  değişen görüntü pikseli ve fiziksel 2C02 zamanlaması henüz türetilmedi.
  Screenshot'tan türetilen `$2240`/scanline 134 adayı kaynakla desteklenmiyor ve
  runtime'a alınmadı. Tam raster, `$F015` paket girdilerinin canlı state
  üreticileri ve CHR/OAM kompozisyonu açık. Ayrıntılar
  `first_command_field_background_producers_20261027.md`,
  `first_command_field_residual_map_scan_20261027.md` ve
  `first_command_irq_viewport_split_audit_20261027.md`,
  `reference/diagnostics/fceux_newppu_irq_raster_probe_20261027.md` ile
  `reference/diagnostics/first_command_irq_viewport_20261027_164108_utc/README.md`
  içinde.
- 8399 save-state'iyle tekrarlanan yeni sessiz FCEUX bus izi 8400–8953 aralığını
  iki kez 15,17 saniyede oynattı; her yüklemede RAM, PPU, frame/cycle, MMC3 ve
  PPU port imzası doğrulandı. İki 92.992 satırlık iz, tekrar etiketi çıkarılınca
  aynıdır. `$C97B` sabit-bank tüketicisi 66 residual hücrenin tümüne 331 yazım
  yaptı; özellikle 8945. karede `$2372–$237D` panel alt kenarı ROM kaynaklı
  `$04A5` paketinden `9E A9 A9 A9 A9 A9 A9 A9 A9 A9 A9 9F` olarak yazıldı.
  Paket üreticisi ROM bank `$1F` `$F015/$F114` olarak belirlendi ve iki-pass
  RAM izi 1.451 paketi / 7.191 payload baytını tekrarlar arasında byte-byte
  eşitledi. Düzeltilmiş input trace `$05CE` son yazarını frame 8905'te bank
  `$0B:$8342` olarak, `$F015` girişindeki `$05CE=$A0/$05CD=$80` durumunu da
  doğruladı; `$063D=$02` writer'ı `$1F:$F009` olarak bulundu. Bunları üreten
  ROM transition/selector helper'ları Godot'a taşındı, ancak active route event
  state'i henüz bağlanmadı. `$0635/$0637` holder koordinatları hâlâ seçili RAM
  kaydı/oyuncu durumuna bağlı. Eski `$06CE` watch değeri bu operand için kanıt
  sayılmaz.
  Kayıt, yöntem ve satır doğrulaması
  `reference/diagnostics/first_command_ppu_bus_trace_20261027_181102_utc/README.md`
  içinde.
- Aktör zinciri `$44 → $5C → $F1` için Godot ROM'dan üç sabit endpoint aktör
  kaydı, `$F7` pozları, `$0546` grafiği ve CHR banklarını üretebiliyor;
  `$A38A → $A390` duruşunu da uygular. Dar kontrol 41 sprite üretti; ilk 164 OAM
  baytı ve 16 sprite-palet baytı frame-8953 doğrulama verisiyle eşleşti. Palet
  adreslemesi düzeltildi: normal oyuncuda adım 5 bayt, ID `$08` → indeks `$08` →
  `$B834`. Ayna yolunda ROM kaynak kodu da kısmen çözüldü: `$FD 02`, `$05FB`
  bayrağını okuyup `$052A`'ya `$00/$40` döndürüyor; `$F6` `$40` bitini
  değiştiriyor. İlk aktör sahnesinden önceki senaryo `$36` ise `$FD 00` ile
  `$0441` oyuncu kaydı ve `$0638` üzerinden ayna sonucunu üretiyor; sabit-bank
  `$ED0C` köprüsü `$052A`'yı renderer girdisi `$0517`'ye kopyalıyor. Sessiz,
  aynı-girdili FCEUX izi `$052A=$40` değerini frame 8624'te, `$0517=$40`
  kopyasını frame 8656'da ve endpoint frame 8953'te `$0517=$40,$052A=$00`
  durumunu doğruluyor. F1 constructor/interpreter kaynak haritası ayrıca
  tamamlandı; `$800F` göreli beklemeleri ve `$F6` actor-record silmeleri ROM
  baytlarından çözüldü. Dört-byte senaryo kaydındaki `$0524` callback ile
  `$0528` actor-stream seçicileri ve `$ECFA–$ED06` worker launch ayrı yollardır.
  `RomF1ActorRecordConstructor` artık animation `$8F` içindeki beş `$F1`
  paketini hash-korumalı `$88E4/$A1B4/$AC47` ROM tablolarından 21-byte actor
  kayıtlarına dönüştürüyor; dar kontrol bu beş kaydı geçti. Bu, `$80AA`
  constructor dilimini kapatır ama aktörleri production rotaya kurmaz veya
  animasyonlarını yürütmez. Route'ta task/callback/continuation state'i
  olmadığı için kare-kare actor üretimi hâlâ açık; sabit yakalama değeri
  runtime'a taşınmadı. Bak:
  `reference/rom_extract/gameplay/actor_packet_constructor/f1_actor_record_constructor_slice_20261028.md`,
  `first_command_actor_palette_and_mirror_source_audit_20261027.md`,
  `first_command_actor_fd_mirror_transform_audit_20261027.md`,
  `fresh_kickoff_actor_initialization_rom_audit_20261027.md`,
  `first_command_actor_writer_trace_source_map_20261027.md` ve
  `first_command_field_live_source_summary_20261027.md`,
  `reference/rom_extract/gameplay/first_command_actor_animation_tick_source_audit_20261028.md`,
  `reference/rom_extract/gameplay/first_command_scenario_event_continuation_audit_20261028.md`.
- İlk menü saha adayı için actor descriptor parser'ı ve 41-sprite ROM-CHR/OAM
  builder'ı mevcut; eski “descriptor/OAM çözülmedi” açıklaması düzeltildi.
  Builder henüz canlı route-time oyuncu state'i, `$0517` ayna state'i ve actor
  cadence'ini almıyor. Frame-8953 yakalama değerleri runtime'a sabitlenmedi;
  ilk menüde gerçek oyuncuların gösterimi ve kare-kare hareketi açık.
- Bank-`$10` oyun senaryosu okuyucusunun 4 baytlık kayıtları, `$F0–$FF`
  handler tablosu, `$35/$36` başlama senaryoları ve B→`$44` komut-paneli yolu
  hedef ROM'da byte-check edildi. `$C50F`, bank-$0B callback'i için `$8009→$814C`
  başlangıç dönüşünü kurarken `$803F` okuyucusuna senkron döner; `$814C`
  callback'i `$C512→$CAF7` ile scheduler'a çıkar. Aynı dört-byte senaryoda
  `$0524` callback seçicisi ile `$0528` actor stream seçicisi ayrı tüketilir;
  fixed `$ECFA–$ED06` actor worker'ı başlatır. Callback, continuation ve task
  RAM'i route runtime'da bulunmadığı için kısmi senaryo VM'i hâlâ production
  mantığı diye eklenmedi. Ayrıntı
  `reference/rom_extract/gameplay/first_command_scenario_event_continuation_audit_20261028.md`.
  ROM-only route adımlayıcısı receiver seçimine kadar
  `$A117`'yi 8.446, `$C9C5`'i 133 kez çalıştırdı; hash'e bağlı RNG yeniden
  yürütümü receiver slot 6'yı frame 8593'te çözüp mevcut 3.901 RAM checkpoint'iyle
  eşleşti. Kaynak kodu denetimi, normal NMI yolunda `$C9C5` giriş carry'sinin
  artık belirsiz olmadığını gösterdi: `$C7CA → $C9E9` döngüsündeki `CPY #$06`
  carry'yi kuruyor ve `$C7E4 JSR $C9C5` öncesindeki komutlar değiştirmiyor.
  Buna karşılık `$0300/$0700/$0780` operand dizileri route/setup yazımlarına göre
  dinamik; `$001B` bit 6 da `$A117` ile `$C9C5` yolunu seçiyor. Godot'ta bu RAM
  üreticileri ve NMI/task cadence'i modellenmediğinden genel oyuncu durumu hâlâ
  route sağlayıcısına bağlanamıyor; slot 6 yalnız kayıtlı girdi izi için
  doğrulandı. Ayrıntı `first_command_player_state_source_20261027.md` ve
  `first_command_rng_source_execution_details_20261027.md` içindedir.
- Maç-0 receiver yolu ROM'da daha açık: kickoff'ta `$E2 & 7`, 5–7 değerleri
  için 5 çıkarımı ve `$DC82=[05,06,07,09,0A]` tablosu `$05FC`'ye sonucu
  yazıyor; `$DB13–$DB16` bunu `$0441` current-player slot'una kopyalıyor.
  Bu yüzden slot 6 yalnız mevcut kayıtlı route'un sonucu; genelleştirilmiş
  runtime seed olamaz. Rakip Fluminense takım/formation/clone-stat tabloları da
  ROM'dan okunabiliyor, fakat ilk menü öncesi rakip enerji yazıcısı bilinmiyor.
  Bak: `first_command_live_player_opponent_state_audit_20261027.md`.
- Aktör ROM zinciri `$EE9F → bank-$14 $83D9/$84DC → bank-$16 $8000` izinde
  1.414 draw kaydı / 473 kare boyunca descriptor ve motion script köklerini
  açıklar. Godot OAM builder tek frame-8953 pozu 41 sprite / 164 bayt için
  FCEUX OAM'ıyla tam eşleştirir, ancak builder hâlâ route-time saha sahnesine
  bağlı değil. Yeni FCEUX RAM-writer izi kare 8399'da anonim bellek-içi
  save-state alıp RAM/PPU/mapper/kare/çevrim checkpoint'ini her yüklemede
  doğruladı; 8400–8953 aralığını iki kez oynattı ve iki çıktıyı byte-byte aynı
  buldu. Her replay'de 7.662 RAM yazımı (7.523 aktör kaydı, 139 saha alanı) ve
  3.371 `$83D9/$84DC/$EE9F` callback'i kaydedildi. `$F1` constructor'ın `$80BF`
  kayıt temizleme, ROM pointer'larını ve koordinat baytlarını yazma adımları ile
  görünüş/hareket yorumlayıcılarının writer PC'leri kaynak baytlarına eşlendi.
  FCEUX `-11` ile kapandı; tamamlanma işareti, yazım akışı ve tekrarlar
  doğrulandı. Trace yalnız bu aynı input rotasındaki yazarları gösterir; tek
  başına yorumlayıcı kare zamanını veya çağrı cadence'ini kanıtlamaz. ROM-native
  animasyon byte spanları `$8F/$4E/$66/$4C` (senaryo `$35/$36`) ve
  `$78/$79/$90/$E6` için pointer tablosu sınırlarıyla çıkarılıp doğrulandı;
  `$79` içindeki `$F0` bir `$F1` operandı olduğundan ilk-F0 taraması
  kullanılmıyor. Olay bağlantıları da byte-check edildi: `$35→$8F`,
  `$36→$4E/$66/$4C`; `$36` kaydı `$E6`, `$F8 $961A` ile `$78` akışına atlıyor;
  `$E233`'ün başlattığı senaryo `$1E`, `$90` akışını seçiyor. Bu kaynak
  komutlarının kaynak çağrı ritmi şimdi kısmen çözüldü: `$800F` düşük-byte
  beklemeleri ve `$F6` aktör silme operandlarıyla `$E6 → $78` göreli animasyon
  tikleri 0/20/22 olarak çıkarıldı ve aynı-girdi FCEUX constructor kareleriyle
  uyuşuyor. Ancak olay worker'ı ve actor-loop kaynak olayları route runtime'da
  bulunmadığı için bu tikler henüz çalıştırılmıyor. Ayrıntı
  `first_command_actor_animation_tick_source_audit_20261028.md`. Yeni
  `Bank10ScenarioBytecodeReader` `$1E/$35/$36` akışlarını, alanlardaki `$F0`
  dönüşümlerinin `$FF` sonucunu, `$F4/$F5/$F6` için sırasıyla `$40` yazma,
  `$00` yazma ve XOR `$40` işlemlerini; `$F7/$F9` RAM atamalarını kaynak
  ofsetleriyle çözüyor. `$FD 02` yalnız caller `$05FB` verildiğinde çalışıyor;
  `$FD 00` oyuncu/RAM bağlamı isteyip sonuç üretmiyor. `$FB` için yalnız dört
  exact hash-checked rota stream'inde caller depth=0 ise root termination
  sınıflandırılır; nested/missing-depth dış continuation ve tanınmayan komutlar
  fail-closed kalır. Eski senaryo
  audit'indeki `$35` başlangıç metni de yanlış biçimde sonraki senaryo
  baytlarıyla birleştirilmişti; `$B7CD` doğru kaynak başlangıcı artık
  `F9 EB 44 02 3A 8F 73 FB` olarak kaydedildi. Genişletilmiş Godot denetimi
  geçti; task/callback worker akışı, mutlak kare zamanlaması ve route entegrasyonu hâlâ açık.
  `RomActorAnimationStreamDecoder` sekiz bank-$14 akışının byte sınırlarını,
  `$F1` paketlerini, `$79` içindeki `$F0` operandını ve `$E6 → $78:$961A`
  yönlendirmesini doğruluyor. `decode_timeline()` / `decode_scenario_event_record()`
  `$800F` göreli beklemelerini ve `$F6` actor-record silmelerini ROM
  baytlarından çıkarıyor; `$E6→$78` paketleri tick 0/20/22'de. Godot 4.7.2
  dar denetimi geçti. API route'a bağlı değil: `$C50F` task, `$814C` callback,
  `$EC94` wait ve `$ECFA` actor-worker handoff'larını yürüten state ile
  OAM/runtime actor üretimi hâlâ yok.
  FCEUX hızlı tekrar yöntemi `AGENTS.md`'ye eklendi: aynı-girdi ölçümlerinde
  adlandırılmamış bellek-içi durum, imza doğrulaması ve tekrar oynatımı kullan;
  kullanıcı save slotlarını değiştirme. Bu yöntem 8399 kontrol noktasındaki
  aktör izinde iki byte-byte aynı geçiş verdi. Daha erken 7393 kontrol noktasını
  izleme iki ayrı FCEUX 2.7.0/NewPPU başlatmasında ilk karede takıldı; her iki
  süreç de tanılama ilerlemesi üretmeden durduruldu ve save state oluşturulmadı.
  Bu başarısız girişimler `reference/diagnostics/first_command_rng_preinit_writer_trace_20261027_173304_utc/`
  ve `..._174208_utc/` altındadır. ROM-only stepper'ın `$0300/$0700/$0780`
  RAM yazılarını kaynak PC/bank/frame/cycle ile izleyebildiği doğrulandı; tek
  tam-route ölçümü frame 4800'de 1:50 sonra durduruldu ve tablo üretmedi. Bu
  izleme yönteminin maliyeti ve sınırları
  `reference/diagnostics/source_stepper_rng_operand_writer_instrumentation_20261027.md`
  içinde; pre-8400 operand yazarları hâlâ bilinmiyor.
  ROM-only statik follow-up `$001B.6` NMI seçimini ve `$C9C5` operand
  bölgelerini ayırdı; doğrudan `$C421` yolu bank-$02 `$A000` içinden `$A117`'ye
  gider, `$A21B` farklı dispatcher koludur. Reset `$0300/$0700/$0780`'ı
  temizler; bu sayfalar canlı kayıt/ses/oyun RAM'idir, ROM tablosu değildir.
  `$0300` kayıtlarını `$DB62` enerji kurucusu ve `$DC07` formasyon yolu
  pointer üzerinden yazar. Buna rağmen checkpoint öncesi tüm operand yazarları
  ve genel girdiyle runtime üretimi açık; mevcut replay exact input hash'ine
  bağlı ve production rota RNG/receiver/`$E14D` olaylarını üretmiyor. Bak:
  `reference/rom_extract/gameplay/first_command_rng_pre8400_static_audit_20261028.md`.
  Başarılı
  iz `reference/diagnostics/first_command_actor_writer_trace_20261027_170114_utc/`,
  ROM kaynak haritaları `first_command_actor_writer_trace_source_map_20261027.md`
  ve `first_command_actor_scenario_event_source_audit_20261027.md`,
  eski başarısız deneme ise `first_command_actor_writer_trace_20261027_151623_utc/`
  altındadır.
- On dört ROM-only maç cue'su Godot'ta yüklenip dispatch edildi; bu kontrol,
  aynı-girdi cue başlangıç zamanını veya route PCM'ini doğrulamıyor. ID 2 sonrası
  cue zinciri ve ses karşılaştırması hâlâ açık.
- Dış kaynak incelemesi Japon maç ilerleme çizelgesini, Çin animasyon-ID
  kataloğunu, adres notlarını ve eşleşen banklar için GitHub disassembly'sini
  değerlendirdi. Bunlar Fluminense–São Paulo ilk maç adını ve bazı animasyon
  etiketlerini destekliyor; rota yazıcılarını, genel RNG'yi, saha rasterini veya
  ses zamanlamasını çözmüyor. Türk ROM baytlarıyla uyuşmayan offset etiketleri
  yerel akışın yerine kullanılmadı. Ayrıntı
  `first_match_external_reverse_engineering_review_20261027.md` içinde.
- Dar Godot kontrolleri cutscene VM, KICK OFF route wiring, saha-adayı kaynak
  verileri, panelin 11 ROM packet satırı, dinamik oyuncu/stat satırları, dört
  seçim etiketi/blink packet'ı, input state'i, 14 cue yüklemesini, mevcut
  açılış→başlık handoff'unu ve açılış ses yaşam döngüsünü geçti. Bunlar tam rota
  veya uçtan uca görsel/ses eşliği anlamına gelmiyor.
- 28 Ekim 2026 Godot 4.7.2 tekrar doğrulaması: ROM animasyon göreli-tik
  denetimi geçti; route doğrulaması ID 1 → `$44`/MEETING → ID 2 → kickoff
  geçidi → ilk panel yolunu geçti. Son panel durumu bu tanılamada doğrulama-only
  endpoint RAM fixture'ından geldi; 452/512 karo ve 32/32, 26/32 öznitelik
  eşleşti. `$55` cue sunucusu 14 ROM-only cue denetimini geçti. Godot 4.7.2
  Dummy audio-server Master-bus yakalaması, üretim cue presenter'ından ilk
  `$55` isteğinin beş saniyesini FCEUX PCM'iyle karşılaştırdı: 219.693 kaynak-
  zamanlı örnekte `r=-0,250135`, RMSE `5612,314`, 7 tam eşleşen örnek; ilk
  sıfır-olmayan örneğe hizalanmış 219.627 örnekte `r=0,380653`, RMSE `4004,443`,
  40 tam eşleşen örnek. Godot'un ilk sıfır-olmayan örneği kaynakta beklenen
  807'ye karşı örnek 873'te çıktı (+66 örnek). Tekrarlanan iki yakalama aynı
  WAV hash'ini üretti. Bu dar cue yakalamasıdır; tam route PCM ve ROM/gerçek NES
  eşliği doğrulanmadı. Hiçbir futbol aksiyonu onaylanmadı.
- Hedef ancak ara maç akışı ve ROM-derived ilk panel production route'a
  bağlanıp aynı girdide görsel, zamanlama, seçim ve ses kıyasları ile ROM/
  emülatörsüz çalıştırma doğrulandığında kapanacak.
- Sonuç yalnız aynı girişte görüntü, süre, seçim ve ses karşılaştırmaları
  geçtikten sonra tamamlandı sayılacak. Açık kalan eşleşmeler burada açıkça
  listelenmeye devam edecek.

## Açılış hedefinin kapanışı — 27 Ekim 2026

- Temiz Godot 4.7.2 kopyası `.nes`, emülatör, yakalanmış WAV ve ekran görüntüleri olmadan açılıyor. Aynı girişle görünür 256×224 alanın 4.693/4.693 karesi ve FCEUX referansının 3.442.925 ses örneğinin tamamı eşleşiyor. Başlıkta `KICK OFF` seçili kalıyor; Continue veya hikâye akışına girilmiyor. Ana sahne, ses yaşam döngüsü ve klavye/kol seçimi denetimleri geçti.
- ROM-derived source clock, Start yoklaması, başlık kuyruğu ve sanal ilk piksel olayı Godot akışına bağlı. Canlı pencere profili Godot 4.7.2 / Apple M2 Pro'da açılışı 77,302 saniyede tamamladı; zaman zaman işletim sistemi/ekran sunum hıçkırıkları sürüyor.
- F8 dönüşündeki 12 FCEUX PC kancası ve MMC3 bankı ROM-only rotayla aynı sırada. FCEUX kancaları adımlayıcıdan +2…+6 CPU çevrimi ileride; neden henüz kanıtlanmadı. FD kare 3476 `$885D/$8887` kancaları +2 çevrim; aynı karedeki beş PPU yazımı tam eşleşiyor. FD’nin diğer izlerinde kare 1525 ve 1756 yazım kuyruklarında +3/+7 çevrim artıkları var.
- Açılış ses WAV'i ROM-only APU/DMC olayları ve FCEUX WaveHi filtresinden yeniden üretilip FCEUX PCM ile byte-byte eşleşiyor. Tek DMC byte'ındaki +3 çevrim etiketi farkı (index 84.665, `$C0C4=$F1`, frame 3601), aynı sound-hook içindeki FCEUX ve ROM-stepper olay sırası farkı olarak doğrudan ölçüldü; bu fiziksel NES DMA zamanlamasını kanıtlamıyor. PCM bundan etkilenmiyor.
- Açılış kaynak hedefi tamamlandı; bu, fiziksel NES'in alt-kare/donanım zamanlamasının kanıtlandığı anlamına gelmiyor. Godot masaüstü sunumu donanım scanout fazına kilitli değil. Ayrıntılı ölçüm ve sınırlar aşağıdaki kayıtlarda korunuyor.

## Doğrulama kayıtları — 27 Ekim 2026

### 27 Ekim doğrulama ve hızlandırma güncellemesi

- **F8 CHR seçicileri:** `$7C/$7E` artık frame-3597 RAM anlık görüntüsünden
  sabitlenmiyor. Godot, seçicileri doğrulanmış proje kaynağı
  `reference/rom_extract/intro/background_17.bin` içinden (`$A373`, ROM dosya
  ofseti `0x00E383`) okuyup ROM'daki `$75/$76 → $8E/$8F → $90/$91` kopya
  sırasını izliyor. ROM-only adımlayıcının dört seçici-kopya çevrimi sessiz,
  aynı-girdili FCEUX PC ve RAM-write iziyle tam eşleşti: frame 3555'te `$8B3F`
  5725 / `$8B44` 5735; frame 3597'de `$8CA7` 6570 / `$8CAB` 6576. Dar Godot
  runtime denetimi de kare 3555 ve 3597'de geçti. Karşılaştırma aracı ve FCEUX
  iz betiği `tools/diagnostics/compare_f8_selector_fceux_cycles.py` ile
  `tools/diagnostics/trace_f8_selector_fceux_cycles.lua`; kaynak anlatımı
  `reference/rom_extract/intro/f8_00_sequence_trace.md` içinde.
- **ROM/emülatörsüz çalışma:** Temiz kopya
  `/tmp/ct2-opening-release-verified-20261027/` `.nes`, `.fm2`, emulator
  yakalamaları, WAV referansları ve gözlem ekranları olmadan yeniden içe
  aktarıldı. Godot 4.7.2 importu, açılıştan başlık ekranına geçiş, klavye/kol
  cursor kontrolleri ve ses cue/tail/scene-teardown denetimleri geçti. Kopyada
  yalnız ROM'dan çıkarılmış oyun verileri ve gerekli dış RGB paleti bulunuyor.
- **Eski yakalama/prototip görselleri:** `assets/opening/intro/` etkin ana
  sahneden kullanılmıyor. Klasörün kök `.gdignore` dosyası eski PPU timing ve
  yakalama PNG'lerinin Godot'a içe aktarılmasını önlüyor; `.gitignore` da bu
  eski prototip çıktılarının yanlışlıkla kaynak pakete girmesini engelliyor.
  Godot ana sahnesi görselleri ROM CHR/palet/nametable/OAM verisi ve çözümlenmiş
  olaylardan çiziyor.
- **Start poll/çevrim izi:** 27 Ekim sessiz, aynı-girdili FCEUX izi
  `$802C/$8030/$8032/$8048` ve `$0700=$01` olaylarını frame 4661'de ölçtü.
  ROM-only stepper'da CPU I bayrağı IRQ kabulünde, PPU kredi bitip IRQ handler'ın
  ilk komutu çalışmadan dönüldüğünde `prev_p`'ye aktarılmıyordu; aynı MMC3 IRQ'su
  `$C506`'da ikinci kez kabul edilip iki poll fazını yaklaşık 257 çevrim
  kaydırıyordu. Kaynak stepper, erken dönüşten önce I maskesini senkronize edecek
  şekilde düzeltildi; bu değişiklik Godot runtime'ına taşınmadı. Temiz aynı-girdi
  FCEUX karşılaştırmasında 4.653/4.653 poll eşleşiyor, 4.649'u ±3 çevrim içinde,
  en büyük artık 7 çevrim; eski frame 3598 `+259` ve 3601 `+263` farkları artık
  sıfır, frame 4661 handoff poll'ü de tam eşleşiyor. Düzeltilmiş stepper SHA-256
  `f20ca13ee59e1080ad0bef03b70001f53b2cd94c0af6e1d21a241e18288ecfe8`.
  Kanıt ve eski baseline: `reference/diagnostics/start_poll_rom_source_timing_20261027/`.
  `rom_source_clock_schedule.json` artık 4.692 kaynak-kare çevrim uzunluğunu ve
  4.653 ROM-poll fazını Godot'a veriyor. Start basma/bırakma zamanları host
  saatinde kaydedilip `$802C` poll'ünün kaynak çevrimindeki zamanına göre
  değerlendiriliyor. Frame 4661'de poll +4.288, `$8048` kaynak-stepper delta'sı
  +36 çevrim. Bu, CPU'yu çalışma anında yürütmek değil, ROM-only yürütümden
  paketlenmiş deterministik kaynak saati kullanmaktır; fiziksel 2A03 fazını
  kanıtlamaz.
- **Kaynak kare saati:** Runtime frame 4661'e dek tek bir 60.0988 sabitini
  tekrarlamak yerine ROM-only stepper'ın her frame için verdiği CPU-cycle
  süresini kullanıyor; host gecikmesinde kesirli çevrim korunup gereken kaynak
  frame'leri tamamlıyor. Kaynak route'un Start sonrası frame-clock kayıtlarını
  açılışı beklerken kullanmamak için frame 4661 sonrası kayıtsız devam nominal
  NTSC süresine döner.

- **Ses:** Aktif Godot WAV'i, sağlanan ROM'dan üretilen CE6 CPU/APU/DMC
  olayları ve sabitlenmiş FCEUX WaveHi/SexyFilter koduyla yeniden üretildi.
  Bağımsız ikinci derleme dâhil FCEUX 2.7.0 aynı-girdi referansının
  3.442.925 örneğinin tamamı eşleşiyor (SHA-256
  `445afa1fc9e35ffd05e4eded941626cd728f5d1034e859e9601aa7a9f472edc4`).
  255/256 kanal kazancı kaydedilmiş FCEUX profilidir; fiziksel NES analog
  çıkışı iddiası değildir. Bağımsız yeniden üretim tarifi ve doğrulama:
  `reference/rom_extract/audio/opening_audio_build_and_pcm_validation_20261027.md`.
- APU write-cycle labels and all DMC byte/address/value pairs match. The sole
  +3-cycle DMC label difference is directly traced at frame 3601 (`$C0C4=$F1`):
  FCEUX hook 34,141,806 enters at cycle 107,214,607, reads the byte on DMR cycles
  608–611, and exits at 611; the ROM stepper places those phases at 611–614
  after the same three-cycle opcode batch. This is a measured software
  event-order difference, not a physical NES timing result. The PCM remains
  byte-identical; capture and audit are linked from the audio provenance note.
- **EC akışı:** İlk kayıt kare ankrajları ve `$EC $02` için özel yakalama
  beklemesi kaldırıldı; sayaç ROM `$84FC → $895D → $896D → $89FF` çağrı akışı
  ve metin hız sayacından ilerliyor. RAM'de 1.377/1.377, PPU nametable
  denetiminde 16.524/16.524 bayt eşleşti. Güncellenmiş akıştaki seçilmiş 179
  kare ve tam 0–4692 yeniden yakalaması doğrulandı. FCEUX açılış OSD'si
  maskelendiğinde görünür 256×224 alan 4.693/4.693 karede tamamen eşleşiyor.
  Ham 256×240 alandaki 4.684 tam kare dışındaki 142 piksel farkı, kare
  2369–2377'de yalnızca y=0 overscan satırında.
- **F1/FD akışı:** Kare/PC'ye bağlı mod ve geometri tabloları kaldırıldı. Mod
  ROM `$4A/$4B` parlaklık sayaçlarından; FD dikdörtgeni de `$84CF–$84DD`
  başlangıcı ve `$8520` E-komut mantığındaki `$4F/$50/$54` durumundan
  hesaplanıyor. 14/14 mod RAM'i, dokuz FD RAM durumu ve 14/14 etkilenen
  görüntü karesi eşleşti. Sonradan kare 3476 `$885D/$8887` dönüş PC'leri de
  FCEUX'te ölçüldü (+2 çevrim); beş PPU yazımı tam eşleşti. Kanıt:
  `reference/diagnostics/f1_fd_rom_state_20261026/README.md` ve
  `reference/rom_extract/intro/fd_scene_clear_trace.md`.
- **Tam görsel karşılaştırma:** EC, F1/FD ROM durumu, A160 düzeltmesi ve olay
  tabanlı başlık kuyruğunu içeren tam yakalamada görünür 224 satırın 4.693/4.693'ü
  tamamen eşleşiyor. Ham 256×240 farkı 142 piksel; hepsi 2369–2377. karelerdeki
  y=0 overscan satırında. Sonradan F8 kapısı kaynak olayına geçirildi; 3966–3969
  kareleri önceki tam Godot yakalamasıyla piksel piksel aynı. Tam yakalama raporu:
  `reference/diagnostics/opening_runtime_full_20261026_rom_event_handoff/README.md`.
- **A160 zamanlaması:** PPU yazım zaman çizelgesi şimdi her satırın slot-2
  kancasındaki güncel `$2001/$2000` değerini kullanıyor. MMC3 kancası 507/507;
  tam ROM-only bus replay'i 8.714/8.714 yazımda çevrim, satır, nokta ve değer
  bakımından FCEUX ile aynı. Kare 1029/1760/2121 Godot görüntüleri de tam.
  Rapor: `reference/diagnostics/a160_fceux_subframe_timing_blocker_20261026.md`.
- **Başlık kuyruğu:** Godot artık kare eşikleri yerine 330 ROM-stepper olayını
  tüketiyor: 31 NMI, 27 doğrulanmış kapasite bekleme/dönüş çifti, 242 `$A029`
  paketi, `$8AF7` yükleyici ve `$807A` son kurulumu. İlk NMI frame 4662'de,
  son tüketici frame 4692'de; test KICK OFF'u seçili bırakıyor ve klavye/kol
  imleci geçiyor. Olay sırası ve kuyruk kararları ROM'dan türetildi, yakalanmış
  ekran kareleri kullanılmadı. Godot parse, endpoint ve klavye/kol kontrolleri
  geçti.
- **F8 dönüşü:** `F8 $00` sonrasındaki `+1 kare` varsayımı kaldırıldı; Godot
  `$A559 → $880A → $C4B9 → $8879 → $8508` ROM PC olaylarının frame-3968
  scheduler dönüşünü kullanıyor. Sonradan yapılan doğrudan FCEUX kıyasında
  3966–3969 görünür karelerinin dördü de 57.344/57.344 pikselde eşleşti;
  3968–3969, FCEUX'ün değişmemiş siyah 3967 görüntüsüdür. Sonradan aynı girişte
  12 FCEUX PC kancası ve MMC3 bankı doğrulandı; FCEUX cycle etiketleri adımlayıcıdan
  +2…+6 çevrim ileride. Kanıt: `reference/rom_extract/intro/f8_00_sequence_trace.md`
  ve `reference/diagnostics/f8_helper_return_pc_cycle_audit_20261027/`.
- **Kalan zamanlama sınırı:** Açılış sunumu ve kayıtlı FCEUX PCM eşleşiyor; düşük
  seviyeli çevrim etiketleri tamamen eşleşmiyor. Tek DMC byte'ında +3 çevrim,
  seçilmiş FD/F8 kancalarında +2…+6 çevrim ve Start yoklamalarında mutlak olarak
  4.652/4.653 değer ±3 çevrim içinde (en büyük artık 7). Stepper her DMC okuması başına bir taşınan CPU çevrimi
  sayıyor; FCEUX APU yazımları 45.452/45.452 çevrimde, DMC byte zamanları
  104.105/104.106 çevrimde eşleşiyor (tek fark +3). Fiziksel 2A03 halt/get-put
  fazı ve 3/4 çevrimlik DMA bus tutuşu modellenmiyor. Başlık Start yolu için
  `$802C/$8030/$8032/$8048` stepper çevrimleri frame 4661 FCEUX PC kancalarıyla
  eşleşti. Bu poll çizelgesiyle Godot Start'ın tutulup bırakılmasını poll anında
  değerlendiriyor; frame-4661 poll'u ve `$8048` geçişi ROM-stepper çevrimleriyle
  aynı sanal saate bağlandı. Başlık kuyruğunun son paketi `$8048`'den 920.030,
  ilk görünür ROM-türevi başlık pikseli ise 925.729 CPU çevriminde (line 39/dot
  118) oluşuyor; Godot tam başlık dokusunu bu sanal piksel olayına kadar saklıyor.
  Aynı kaynak-saat doğrulaması son paket ile piksel eşiği arasında 5.699 çevrim
  olduğunu denetliyor. Bu, kaynak-stepper/pinned-FCEUX yazılım modeli zamanıdır;
  masaüstü pencere sunumu monitörün scanout fazına kilitlenmez. Fiziksel
  2A03/2C02 zamanını yalnız gerçek konsol ölçümü kapatabilir.
- **Start denetimi:** ROM'da `$802C` Start bitini okuyup `$8030`'da dallanıyor;
  `$8048` başlık geçişi için ses-stop komutunu yazıyor. 27 Ekim muted FCEUX
  replay'i frame 4661'deki PC çevrimlerini ve `$0700=$01` yazımını kaydetti;
  ROM-only stepper'ın `cycle_after_instruction` değerleri beş olayda FCEUX
  hook/write çevrimleriyle aynı. Godot input history'den Start'ın kaynak
  `$802C` poll anında basılı olup olmadığını seçiyor; poll→`$8048` için ROM-only
  stepper'ın 36 çevrimini ve başlık kuyruğu event saatini kullanıyor. Ana
  doğrulama, poll öncesi basılıp bırakılan kısa basışın reddini ve poll sırasında
  tutulan Start'ın doğru sanal çevrimde kabulünü denetliyor. FCEUX kancalarının
  38 çevrim convention'ı ile ROM-stepper'ın 36 çevrim PC-start convention'ı
  farklıdır ve raporda ayrıdır. Rapor:
  `reference/diagnostics/start_poll_rom_cycle_alignment_20261026.md`.
- **Start/piksel entegrasyonu:** Başlık kuyruğu son paketi 920.030 kaynak CPU
  çevriminde tüketiyor; test başlık görselinin bu olayda erken görünmediğini,
  925.729 sanal piksel çevrimine kadar gizli kaldığını, sonra KICK OFF'u seçili
  gösterdiğini doğruluyor. Önceden doğrulanan 4.693 görünür 256×224 oyun karesi,
  ROM CHR/palet/nametable/OAM ve kaynak olaylarla aynı; tam Godot pencere
  scanout'una piksel-altı donanım eşliği iddiası değildir. Ses doğrulayıcısı
  WAV'i handoff boyunca çaldı ve sahne kapanışında stream'i bıraktı.
- **F9 scheduler:** `$A031 F9 01` frame 4541'de dispatch edilir; `$8BB0`'ın
  `$9FA8(A=$01)` beklemesi sonraki `$9EED` bırakımında, frame 4542'de producer'ı
  sürdürür. Kare-4542 RAM'inde `$0628=$39` ve dokuz kuyruk paketi bu akışla
  eşleşir. Yanlış bir önden-release koşulu kaldırıldı; frame 4577–4585 Godot
  RGB çıktısı önceki tam yakalamayla aynı. Bu yeni FCEUX ölçümü değildir.
- **Diyalog cursor'ı:** F2 handler'ı yalnızca `$55` yazı hızını değiştirir.
  Hard-coded F2 cursor reset adresleri kaldırıldı; başlangıç, FD, FC ve E3
  kendi ROM kaynaklı durumlarını kuruyor. Sekiz F2 grubunu kapsayan 16 kare
  önceki tam Godot yakalamasıyla piksel piksel aynı; her FD çağrı noktasının
  ayrı CPU-cycle izi henüz yok.
- **Çalıştırma:** Yerel Godot 4.7.2 importu, ana-sahne handoff ve ses cue/tail/
  stream-bırakma denetimleri geçti. Temiz ROM/emülatörsüz son kopya ve aynı
  kontrollerin o kopyadaki sonuçları da geçti.
- **Canlı hız:** Yeni cycle-clock build'i kare 4661'e 77,302 s'de ulaştı; 11.095
  host process örneği, ortalama 6,967 ms / p95 7,663 ms, en uzun 35,414 ms.
  Kaynak-clock catch-up 18 kare, en büyük tek adım 9 kare; GPU arka plan çizicisi
  aktif ve fallback yok. Bunlar host-loop ölçümleri; 21 uzun host aralığı 21
  kayıp oyun karesi demek değildir. Gecikme olunca ara bitmap'ler masaüstünde
  sunulamayabilir; işletim sistemi/display hıçkırığı tamamen kaldırılamaz.
  Ayrıntı `reference/diagnostics/opening_runtime_realtime_profile_20261027.md`.

Bu bölüm en güncel ölçümleri taşır; aşağıdaki eski tarihli notlar araştırma
geçmişidir ve onun yerine kullanılmamalıdır.

### Ses durumu düzeltmesi — 26 Ekim 2026

Önceki `0,99604` korelasyon ve `%16,43` tam örnek ölçümleri, artık kullanımda
olmayan 256/256 kazançlı aday WAV'e aittir. Aktif 255/256 profilli WAV, ROM
kaynak olaylarından bağımsız yeniden üretimde FCEUX referansıyla 3.442.925
örneğin tamamında byte-byte eşleşir; yakalanmış PCM sentez girdisi değildir.
Aktif manifestin üst seviye karşılaştırma alanları bu sonuçla düzeltildi;
tarihsel raporlar korunuyor. Tek DMC byte çevrimindeki +3 fark ve fiziksel
2A03 analog çıkışının iddia edilmemesi geçerli sınırlamalardır.

## Bitti sayılması için

- Godot projesi doğrudan açılış sahnesinden başlar, intro akışını ve özgün müziği oynatır, ardından başlık ekranında durur.
- Açılışın komut sırası, beklemeleri, yazı/animasyon ilerleyişi, ses tetikleri ve Start geçişi Godot'ta ROM'dan çözülen mantıkla sürülür; yakalanmış emulator karelerini sırayla oynatmak tek başına tamamlanmış uygulama sayılmaz.
- Görüntü üretimi ROM'dan çözülen grafik verisi, palet, tile/sprite düzeni ve zamanlamadan yapılır. Emulator kayıtları yalnız davranışı gözlemleme ve aynı girişte doğrulama içindir; çalışma zamanı varlığı değildir.
- `KICK OFF` ve `CONTINUE` görünür; ikisini onaylamak bu dilimde hikâye veya kayıt akışına geçirmez.
- Çalışan proje `.nes` dosyası veya emülatör gerektirmez. Kullanılan grafik, metin ve ses varlıklarının ROM kaynakları kayıtlıdır.
- Aynı giriş dizisinde görüntü, kare zamanlaması ve ses, kaynak oyunla karşılaştırılır. Açık kalan farklar tamamlandı diye sunulmaz.

## Önceki güncel durum (26 Ekim ölçümlerinden önce; üstteki bölüm geçerlidir)

Aşağıdaki sonraki tarihli notlar araştırma geçmişidir; bir durum cümlesi bununla
çelişirse bu bölümdeki güncel metrikleri esas al.

**En son tam açılış görsel karşılaştırması:** ROM adım yürütücüsünün ürettiği
`$2006` yazım çizelgesi sprite plane-1 satırına aktarıldı. Tam 0–4692 aynı-girdi
Godot yakalaması `reference/diagnostics/opening_runtime_full_20261026_shared_sprite_fetch/`
altında. FCEUX `Power on` OSD'si kare 1–180'de maskelendiğinde görünür 256×224
alan 4.693/4.693 karede ve tüm piksellerde birebir eşleşiyor; foreground
birleşimi de `%100`. Ham 256×240 alanın OSD-maskeli karşılaştırmasında
4.684/4.693 kare tam; kalan 142 pikselin tamamı yalnızca y=0 overscan satırında.
Bu aynı-girdi karşılaştırması FCEUX'in gösterdiği 224 satırlık görüntüyü doğrular;
fiziksel 2C02'nin dot davranışı hakkında iddia değildir.

Üretim çizicisi `reference/rom_extract/intro/rom_source_a160_ppu_write_timeline.json`
dosyasındaki ROM-stepper `$A175/$A178` olaylarını kullanıyor: 3.632 kare / 7.264
yazım. Kaynak CPU adımlayıcısındaki `$CE` mutlak DEC komut maliyeti, FCEUX'in
6 çevrimlik tablosuna göre düzeltildi; aynı-girdi bus kaydı ile 301 değişen karedeki
602 yazımın çevrimi, scanline'ı, dot'u ve değeri 602/602 tam eşleşiyor. Üretime
geçen çizelge, bu 301 karenin görünür 224 satırını da FCEUX ile tam eşleştiriyor;
ham 256×240 kıyasında kalan 50 piksel yalnızca y=0 overscan'da (4 kare).
Önceki tam yakalamanın diğer kareleri değişmedi.

Tam A160 zaman tablosundaki 7.264 yazımın 7.258'i çevrim ve scanline'da,
7.260'ı dot'ta eşleşiyor; altı artık yazım üç sahne/geçiş karesinde (1029, 1760,
2121) bir scanline ve 108–114 CPU çevrimi sapıyor. Üçüncü, sessiz FCEUX tekrar
oynatımı tüm 2.122 kaynak karesini tamamladı ve altı ilgili `$2006` yazımının
gerçek `$A175/$A178` komutlarında olduğunu doğruladı; seçilmiş 166 `$2006`,
`$E000` ve `$E001` olayı mevcut bus iziyle çevrim/değer/PC bakımından eşleşti.
ROM adımlayıcısının IRQ kabul olayı ise gözlenen `$A160` raster-handler girişine
göre üç geçişte 54–57 çevrim geç kalıyor; dot/scanline API'si bu FCEUX Lua
kurulumunda kullanılamıyor ve IRQ hat-assertion çevrimi ölçülmedi. Farkın kaynağı
CPU/IRQ ve PPU alt-çağrı zamanlaması bölgesine daraltıldı, ama altı yazım hâlâ
çözümsüz; genel veya elle kareye uydurulmuş düzeltme yapılmadı. Ayrıntı
`reference/diagnostics/a160_fceux_subframe_timing_blocker_20261026.md`.
ROM-only zaman tablosu ve bütün 301
piksel karşılaştırması `reference/diagnostics/audio/rom_stepper_opcode_ce6_full_4692_20261026/`
altında belgeli. Görsel renderer PPU adresini ROM tile bytes ve kaynak OAM/PPU
durumuyla hesaplıyor; gerçek NES'in açılış nametable RAM içeriği FCEUX'in sıfır
başlatma davranışından ayrı doğrulanmış değil.

CE6 kaynak CPU replay'i 4.692 kare sınırını, 18.736 ses-frame güncellemesini ve
45.452 APU yazımını tam eşleştiriyor. 104.106 DMC byte'ının adres/değeri aynı;
104.105 çevrim eşit, bir byte +3 CPU çevrimi. Bu pinned FCEUX model doğrulamasıdır,
fiziksel 2A03/2C02 ölçümü değildir.

**Başlık geçişi ve giriş kontrolleri:** Godot 4.7.2 ana sahne denetimi frame 0'dan
başladı; frame 4661 Start girdisiyle handoff yaptı ve frame 4692'de `KICK OFF`
seçili başlıkta kaldı. Klavye ve gamepad Up/Down/Select çalışıyor; Start hiçbir
seçeneği onaylamıyor. Yeni üretim WAV'ı `$CE=6` ROM-only CPU/APU/DMC adımlarından
ve ROM ses sürücüsünden, FCEUX WaveHi/SexyFilter koduyla çevrimdışı üretildi;
yakalanmış PCM veya FCEUX zaman damgası sentez girdisi değil. Aynı-girdi FCEUX
PCM korelasyonu önceki `0,98867`'den `0,99604`'e çıktı, RMSE `527,76`'dan `327,08`'e
indi. Geç müzik pencereleri `0,9947–0,9957`, Stop kuyruğu `0,9901` korelasyon
veriyor. Tam örnek eşitliği yalnız `%16,43`; WAV birebir değil. Üretim WAV SHA-256'sı
`8891669e…575cf8f`, eski WAV geri dönüş için
`reference/diagnostics/audio/runtime_audio_pre_ce6_wavehi_20261026/` altında.
Kaynak hash'leri, cue çevrimleri ve açık ses farkları üretim manifestinde ve
`reference/diagnostics/audio/ce6_wavehi_pcm_followup_20261026/README.md` içinde.

**Cutscene/scheduler mantığı:** Runtime ROM komut baytlarını ve ROM'dan çözülen
CHR/palet/PPU verisini kullanıyor; ancak kesit yürütücüsü henüz tam ROM scheduler
ve CPU emülasyonu değil. EC akışlarının ilk kaydı hâlâ gözlemden alınan
38/12/20/29-karelik boşluklarla başlıyor; `$EC $02` için 1800–1839 arası askı
ve bazı F1/FD giriş değerleri de kaynak koşulu olarak çözülmedi. Bunlar sabit ROM
kuralı diye sunulmuyor ve ankrajlar değiştirilmedi. Eksik `$8A0F`
çağıranı/etkinleşme koşulu için gereken dar iz
`reference/diagnostics/opening_runtime_anchor_audit_20261026.md` içinde; başlık
geçişinin alt-kare NMI/ilk üretici bırakma fazı da açık. Bu nedenle tüm açılış
komut ve zamanlama mantığının ROM'dan çıkarıldığı iddiası henüz doğru değil.

Yeni ROM-only kanal izi, geç `$58` döngüsündeki farkı daha da daralttı: frame
4400–4560 arasında DMC okuması/bit kenarı yok; ham tek-seviyelik DMC/pulse/noise
farkı FCEUX'in `255/256` kanal kazancı uygulanınca yok oluyor. Bu kazançtan sonra
pulse 1, pulse 2, noise ve DMC katkıları frame 4481–4661 boyunca çevrim çevrim
eşleşiyor. Üçgen kanalı frame 4481/cycle `133.416.642` başında daha etkin değilken
bile faz/zamanlayıcı bakımından ayrılmış durumda; ilk etkin kenar kaynak modelinde
`133.459.694`, FCEUX'te `133.459.727` cycle'ında. Bu state farkının ilk görüldüğü
nokta frame 380 MMC3 IRQ sırası. Frame 4460–4510 PCM penceresinde üretim,
frame-update ve full-DMC-edge adayları byte-byte aynı; FCEUX'e korelasyon
`0,93508`, nRMSE `0,36881`. Post-Stop kuyruk da ayrı açık: frame 4661–4692
korelasyon `0,66014`; 4655–4685 stop-tail `0,77007`. Üretim WAV'ı ve manifesti
değişmedi. Raporlar `reference/diagnostics/audio/rom_stepper_wavehi_channel_raw_4481_4661_20261026/channel_wavehi_comparison_fceux_volumes.json`,
`reference/diagnostics/audio/rom_channel_state_4481_4578_20261026/` ve
`reference/diagnostics/audio/rom_source_only_late_audio_gap_audit_20261026/README.md`
içinde.

2026-10-26 tarihli yeni tanı adayı, FCEUX NewPPU `runppu()` alt çağrı sınırlarında
işaretli CPU borcunu koruyup IRQ/NMI'ı her opcode öncesi kontrol etti. İlk 381
karenin toplam çevrimlerini ve 1.196 APU yazımını eşleştirdi; 947 DMC byte'ı da
adres/değer sırasıyla aynıydı. Ancak ses zamanlama farkını gidermedi: frame 380
IRQ'sunda ROM adımlayıcı `$9F2C`'ye geçmişken FCEUX `$9F2A`'da kalıyor; frame 381
ses güncellemesi 3 çevrim, ilk üçgen adımı 2 çevrim geç. Pinned FCEUX sınır izi,
IRQ'nun tamamlanmış komutlar arasında geldiğini gösterdi; kaynak adımlayıcı daha
erken, line 48/dot 260'da `$9F27`'ye geçmişken FCEUX `$9F25`'te kalıyor ve
adımlayıcının işaretli kredisi bir PPU-dot'u (16/48 birim) önde. Bu nedenle
kesirli komut çekirdeği gerekçelendirilmiş değil; line 48 başından ilk call/credit
ayrışmasını bulmak sürüyor. Sabit çevrim düzeltmesi uygulanmadı. Üretim WAV'ı
değişmedi. Tanı raporu
`reference/diagnostics/audio/subcall_irq_triangle_candidate_20261026.md` içinde.

**ROM/emülatörsüz çalışma yolu:** `project.godot` ana sahnesi
`scenes/main.tscn` → `scenes/opening_source_runtime.tscn` zincirini açıyor.
Bu runtime zincirinde `.nes` dosyası açan veya emülatör süreci başlatan çağrı
bulunmadı; kullandığı kaynaklar proje içindeki ROM'dan çıkarılmış `.bin`/JSON,
palet dosyaları ve Godot ses kaynağı. Tam 4693-kare yeniden yakalaması da
emülatör çalıştırmadan Godot sahnesini yürüttü. Ek olarak temiz kopyada `.nes`,
`.godot` önbelleği ve yakalama klasörleri olmadan Godot importu, 10 karelik ana
sahne açılışı, başlık handoff'u, klavye/kol imleci ve ROM'dan üretilen sesin
yükleme/akış denetimi geçti. Bu, dağıtım paketi audit'inin veya ses örnek eşliğinin
yerine geçmez; ayrıntı `reference/diagnostics/standalone_clean_runtime_20261026.md`
içinde, kaynak projede ayrı FCEUX tanı araçları bulunmaya devam eder.

Kaynak ağacındaki eski `scenes/opening_controller.tscn` ve
`assets/opening/intro/frame_manifest.json` bu ana sahne zincirinde kullanılmıyor.
Eski `ppu_timing` PNG dizisini ana runtime'a bağlama; güncel görüntü yolu ROM
CHR/palet verisini ve kaynak-komut sunumcusunu kullanıyor.

**Canlı kare hızı:** Güncel sessiz native-window profili frame 4661'e 77,313
saniyede ulaştı (yaklaşık 60,29 kaynak karesi/s). Sürekli ağır çekim yok; 10
host aralığı 16,639 ms bütçesini aştı, en büyüğü 43,13 ms oldu ve kısa catch-up
yaşandı. Bu görsel entegrasyondan sonra pacing gerilemesi göstermiyor ama ara
sıra takılma kalıyor; rapor
`reference/diagnostics/opening_runtime_realtime_profile_20261026_after_sprite_fetch.md`.

**BG08 canlı OAM uzunluğu:** ROM `$96F2/$9727` ve `$91B4–$91F1` davranışı
uygulanıp kare sonu RAM'e karşı 1047–1159 aralığında doğrulandı: 113/113 karede
256 OAM baytının tamamı eşleşiyor. `$82` kaydı başlangıçta 50 sprite (`$C8`)
uzunluğunda; frame 1107'de ilk 56-sprite pozu geldiğinde `$E0`'a büyüyor.
Sonraki 55/56 pozlarında gizli slotun Y temizliği ve hareketi de eşleşiyor.
Rapor `reference/diagnostics/bg08_live_extent_source_runtime_20261026/`, kaynak
izi `reference/rom_extract/intro/bg08_c1_82_shared_oam_trace.md` içinde.

**Soğuk açılış ses sürücüsü bus-cycle izi:** Aynı-girdi FCEUX kaydı frame 9'da
NMI `$C421` girişini cycle 238275'te, `$C449` sürücü çağrısını `$003B=$80` ve
R6=`$0C` iken cycle 240180'de, banklı `$8000` girişini iki çevrim sonra ve
`$C44C` dönüşünü cycle 241033'te kaydediyor. Frame 4'te `$4010=$00` ve
`$4017=$40`, ilk `$4015=$0F` yazımı frame 283'te bulundu. İz 0–283 aralığını ve
19.700 CSV olayını kapsıyor; FCEUX kapanış sırasında status 139 döndürdü ama
tamamlama işareti ve satır sayısı dosyaların kapanıp yazıldığını doğruluyor.
Bu iz runtime WAV'ı değiştirmiyor ve sample eşitliğini kanıtlamıyor. Ayrıntılar
`reference/diagnostics/cold_start_audio_entry_trace_20261026/README.md` içinde.

**Ek ses instruction-hook doğrulaması:** Yeni sessiz FCEUX tekrarı `$C421`'i
frame 9 / cycle 238275'te `$003B=$00` iken yakaladı; `$C428` yazısı `$003B`'yi
238284'te `$80` yapıyor. Frame 4'te `$C685` 111984, `$C687` içindeki `$4010`
yazımı 111988, `$C68C` içindeki `$4017` yazımı 111994 cycle'ında. İlk
`$4015=$0F`, `$8366` komutuyla frame 283 / cycle 8400582'de yazılıyor. Seçilmiş
PC hook'ları kaynak çağrı yolunu ve write sırasını doğruluyor;
`getcyclescount()` iç CPU bus fazlarını ya da DMC DMA saatini vermiyor. Bu yüzden
audio örnek eşitliği hâlâ açık; mevcut NSF builder'ın APU hazırlık kenarı için
builder varsayılanına 1134-cycle düzeltme eklendi ve libgme izinde iki ROM
yazısı 111988/111994'e oturdu. 45.457 APU yazımının yalnızca bu iki satırı
değişti; event/PLAY/DMC callback sıraları aynı kaldı. Runtime WAV ve manifesti
değişmedi; PCM üretimi yapılmadı, bu yüzden sample eşitliği hâlâ doğrulanmış
değil. Kanıt `reference/diagnostics/audio/apu_setup_cycle_alignment_20261026.md`
ve `reference/diagnostics/cold_start_audio_entry_trace_20261026/README.md` içinde.

**EC animasyon duraklaması:** 2680/2682'deki 61 piksellik alt-sol portre farkı,
Godot'un EC döngüsünü `$DC` beklemesi, `$EA` fade'i ve `$FD` temizliği sırasında
ilerletmesinden kaynaklanıyordu. ROM'daki `$0652/$0653` ve dört ilgili PPU byte'ı
beklerken sabit kalıyor. Sunumcu artık bu komut durumlarında sayaç ilerletmiyor;
aynı-girdi karşılaştırmasında 2680 ve 2682 artık 100% RGB tam. Beş EC bekleme
aralığındaki eski küçük farklar, BG08 `$82/$AE08` pozunun 55 descriptor ile 56
slotluk canlı OAM alanı arasındaki kuyruk davranışıyla ilişkiliydi. Önceden
yalnızca görsel gizleme uygulanmıştı; ROM'daki `$96F2` Y temizleyicisi ve
`$91B4–$91F1` hareket döngüsü artık kaynak modeliyle yürütülüyor. 1047–1159
aralığında RAM eşleşmesi tam. Tam açılış yeniden karşılaştırmasında görünür
farkların 18'i bu animasyonların örtüşme sınırlarında; frame 3601 ayrı bir
raster/OAM farkı. EC scheduler slot duraklamasının düşük seviye nedeni de açık.
Ayrıntılar
`reference/diagnostics/ec04_compact_pause_tile_hold_20261026.md` ve
`reference/rom_extract/intro/bg08_c1_82_shared_oam_trace.md` içinde.

**Üst satır çizgisi / FCEUX görünümü:** Sessiz FCEUX 2.7.0 penceresi ROM'u
kayıtlı soğuk-açılış girdisiyle 380. karede durdurularak kontrol edildi. Canlı
NTSC penceresi 256×224; görünen görüntünün en üstünde mavi gökyüzü var. 256×240
ham PPU referansında y=0'da ince renkli satır bulunuyor, ama ilk overscan
satırları FCEUX penceresinde kesildiğinden görünmüyor. Godot'un 256×240 doğrulama
viewport'u ilk anda bu satırı gösteriyordu. İstek üzerine canlı proje penceresi
256×224'e alındı ve 240 satırlık ROM çizimi y=-8 kaydırıldı; böylece emülatörün
gösterdiği satırlar kalıyor, ilk/son 8 overscan satırı kesiliyor. Tanılama
yakalayıcısı 256×240 ham PPU karşılaştırmasını koruyor. Sessiz FCEUX ve Godot
pencere kanıtları `reference/diagnostics/viewport_crop_fceux_20261025/` altında.

**Renderer hızı:** Üretim varsayılanı artık ROM CHR/palet tile-satırlarını 32
RGBA baytlık diziler halinde önbelleğe alıp tek kare tamponuna birleştiriyor;
önceki `Image.blit_rect()` çizimi karşılaştırma seçeneği olarak duruyor. Aynı
headless ölçüm oturumunda 2367–2408 aralığı packed-row yolunda kaynak kare başına
23,365 ms / redraw başına 19,247 ms; referans çizicide 24,246 ms / 21,289 ms
ölçüldü. Böylece çiftli ölçümde redraw %9,6 azaldı. 42/42 background texture
hash'i aynı; ayrıca tam 4693 karelik Godot PNG yakalaması eski çıktıların
tamamıyla byte-byte aynı ve FCEUX metrikleri değişmedi. Gecikme sonrası catch-up sırasında tüm ROM
kareleri ilerletiliyor, yalnız ekranda gösterilemeyecek ara bitmap'ler atlanıyor:
11 karelik kontrollü örnek 178,359 ms'den 23,649 ms'ye indi ve son viewport
SHA-256 aynı kaldı. Redraw hâlâ 16,64 ms NTSC kare bütçesinden uzun; 60 Hz
çalışma kanıtlanmadı. Ayrıntılar `reference/diagnostics/opening_render_state_batching_20261026.md`
ve `reference/diagnostics/opening_runtime_full_20261026_packed_rows/README.md`
içinde.

**Hız denemeleri ve güncel doğrulama (26 Ekim):** Opt-in 8-tile-row byte
cache'i 2367–2408 aralığında 42/42 aynı arka plan hash'ini verdi; iki eşlenmiş
ölçümde kaynak-kare süresi `%4,5–5,9`, yalnız redraw süresi `%7–8` azaldı.
Sonuç yine 16,64 ms bütçesinin üstünde ve tek bir MMC3 aralığıyla sınırlı olduğu
için bu yol varsayılan yapılmadı. `ImageTexture.update()` denemesi toplam
kare süresini iyileştirmedi ve headless görüntü hash'leri sabit kaldığı için
reddedildi. Ayrı native-window GPU shader prototipi 2367–2408 arasındaki 42/42
arka plan karesini mevcut renderer ile RGB düzeyinde eşleştirdi. Aynı çalıştırma
ve viewport texture readback dâhil ölçümde software yol 26,595 ms/kare, shader
yolu 6,771 ms/kare ortalama verdi; ancak doğrulama yalnız BG `$0A` için ve FCEUX'e
karşı değil. Shader ana sahneye bağlı değil; diğer intro arka planlarında aynı
sonucu verdiği ve tüm-açılışta hızlandığı henüz ölçülmedi. Godot 4.7.2'de Dummy
ses sürücüsüyle güncel proje yeniden
kontrol edildi: ana sahne frame 4692'de `KICK OFF` imlecinde bitiyor; klavye ve
gamepad Up/Down/Select çalışıyor, Start seçeneği onaylamıyor; ses WAV'ı,
manifest checksum'u, `$58` yeniden eşleme noktaları ve geçişte durdurma/temizleme
yolu geçiyor. Bu kontroller görüntü/ses örnek eşitliğini veya 60 Hz oynatmayı
kanıtlamaz.

**APU başlangıç yazılarının PCM karşılaştırması:** ROM byte'larıyla kurulan
libgme adayında kaynak izinin doğruladığı `$4010/$4017` yazıları 1134 CPU çevrimi
ötelenerek 111988/111994 callback çevrimlerine hizalandı. Baseline ve aday
yalnız bu iki yazı zamanında farklı; runtime WAV ve manifest değiştirilmedi.
Tanı amaçlı iki tam PCM render aynı girdili FCEUX WAV'ına karşı karşılaştırıldı:
±8 NES-kare kayma aramasındaki en iyi korelasyon sırasıyla `0,02175` ve
`0,04631`, aynı örnek indeksindeki korelasyon ise `0,00917` ve `-0,00618`.
Her ikisi de dalga biçimi eşleşmesi göstermeyecek kadar düşük. Adayın ilk ses
başlangıç çevrimini düzeltmesi PCM/tını eşliğini veya tüm müziğin eşleştiğini
kanıtlamaz. Ayrıntılar
`reference/diagnostics/audio/apu_setup_cycle_alignment_20261026.md` ve
`reference/diagnostics/audio/apu_setup_pcm_comparison_20261026/README.md` içinde.

**ROM-kaynaklı sesin daha dar kontrolü:** Yakalanmış APU yazım çevrimlerini
girdi yapmayan en yakın saklı ROM-NSF adayı sıfır kaydırmalı derlemedir; ROM
ses sürücüsü/müzik/DPCM byte'ları ile ROM-sunumcu `$ED` olay JSON'undan üretilir,
ancak olay zamanlarında hâlâ belgelenmiş ankrajlar ve açık title-stop karesi
vardır. FCEUX WAV'ı yalnız doğrulama için kullanıldığında 260–410 penceresinde
aynı-indeks korelasyonu `0,08934`, ±8-kare aramasında en iyi korelasyon `0,33157`
(−1 kare); `$58` penceresinde `0,82025` (−1), `$68` penceresinde yalnız `0,11329`
(+7) çıktı. Bu kaymalar tutarlı değildir ve PCM eşleşmesi değildir. Daha iyi
FCEUX WaveHi tanı render'ı yakalanmış APU/DMC zamanlarını kullandığı için
standalone kaynak girdisi olarak uygun değil. Kaynak/ölçüm notu
`reference/diagnostics/audio/source_only_opening_segment_feasibility_20261026.md`;
runtime WAV değişmedi.

**`$6E` runner gizli-OAM düzeltmesi:** ROM'dan izlenen 9-bit OAM koordinatı
mevcut `$04/$08` overflow culling yoluna veriliyor; görünür sprite'ların düşük
byte koordinatı değişmiyor. 378–400 ve 4577–4590 aralıklarındaki 37 karenin
tamamı yeni kodla RGB ve foreground'da %100 eşleşti. 380, 381, 382, 394, 4579 ve
4580 ayrı kontrol noktaları da tam eşleşti. Hedef yakalama ve metrikler
`reference/diagnostics/runner_oam_culling_fix_20261025/` altında. `$6E`'nin
`$04` işaretini yazan 6502 rutini hâlâ izlenmedi; bu runtime yolu gözlenen
shadow/OAM ve DMA davranışına dayanıyor.

**A2 ortak OAM satır değerlendirmesi:** Kaynak FB listesindeki OAM slot sırasını
paylaşıp satır başına ilk sekiz sprite'ı seçen düzeltme, 2367–2415 arasındaki
49 aynı-girdi karesinde kontrol edildi. FCEUX'in görünen 256×224 alanında
49/49 kare RGB piksel piksel aynı. Ham 256×240 karşılaştırmasında 142 farkın
tamamı y=0 overscan satırında; y=8–231 ve y=232–239 satırlarında fark yok.
Bu, o pencere için görüntü farkını kapatıyor ama tüm açılışı veya gerçek
2C02'nin dot düzeyindeki OAM değerlendirmesini doğrulamıyor. Güncel renderer ile tekrar alınan kanıt
`reference/diagnostics/oam_scanline_evaluation_20261025_post_renderer_optimization/README.md`
içinde.

**BG08 OAM overflow düzeltmesi sonrası:** 1048–1524 aralığının 477 karesi
yeniden karşılaştırıldı: RGB ortalaması `%99,9902`, foreground-birleşim
ortalaması `%99,9800`; 11 kare iyileşti, 466 kare aynı kaldı, hiçbiri gerilemedi.
Frame 1088 şimdi %100 RGB exact. Son 477-kare yakalama ve metrikler
`reference/diagnostics/bg08_oam_rom_overflow_fix_20261025/` altında.

**BG0B EA temizleme/reset düzeltmesi:** ROM EA handler'ının frame 2904'te
`$007B`'yi `$FF`'den `$00`'a yazdığı `$85B5` (`STA $7B`, file `$05C5`) kaynak
iziyle doğrulandı. Sunumcu artık bu RAM resetini EA temizleme tamamlanma olayıyla
modelliyor; frame numarasına göre kesme kullanmıyor. Geçiş öncesi ve sonrası 16
kontrol karesinin tamamı RGB ve foreground'da eşleşti. 2939–3490 arasındaki 552
karenin tamamı yeniden yakalandı; RGB ve foreground eşleşmesi 552/552 karede
%100. Kaynak izi
`reference/diagnostics/bg0b_ea_scroll_reset_20261025/README.md`, 16-kare
kontrolü `reference/diagnostics/bg0b_ea_scroll_reset_runtime_20261025/` ve tam
aralık `reference/diagnostics/bg0b_ea_scroll_reset_runtime_full_20261025/`
altında.

BG08 scroll düzeltmesinden sonraki önceki tam ölçüm ve ham kareler
`reference/diagnostics/opening_runtime_full_chunks_20261025_211500_bg08_scroll_ff/`
altında; özet ve sınırlar bu klasördeki `README.md` dosyasında.

**Ses çizelgesi kaynak bağımsızlığı için ara adım:** NSF aday oluşturucu artık
ROM sunucusunun JSON çıktısından 12 `$ED` olayını ve ayrı, bayt doğrulamalı
`$8048` Stop olayını alabiliyor. Bu 13 olayın sırası/kimliği/kareleri FCEUX
`$0700` doğrulama listesiyle 13/13 eşleşti. Tanı adayı
`reference/diagnostics/audio/rom_presenter_event_nsf_candidate_20261025_rerun/`
altında; üretim WAV ve manifest değişmedi. Sunucunun zamanlamasında hâlâ
yakalama dayanakları bulunduğundan bu eşleşme sesin PCM/tını eşitliğini veya
tam bağımsız zamanlama üretimini kanıtlamıyor. Ayrıntı
`reference/diagnostics/audio/opening_audio_capture_schedule_gap_20261025.md`.

Bu adayın 3-frame başlangıç kırpımından sonraki WAV'ı 3.420.937 örnek.
Örnek-indeks korelasyonu FCEUX PCM'sine karşı `-0,00569`, dağıtılan WAV'a karşı
`0,02126`; ilk ve son `$58` müzik zarfı yaklaşık 3 kare kaymayla benzer etkinlik
gösterse de bütün ses dalga biçimi eşleşmiyor. Bu tanı WAV'ı runtime'a alınmadı;
dağıtılan WAV ve manifest değişmedi. Ölçüm ve hash'ler
`reference/diagnostics/audio/rom_presenter_event_nsf_candidate_20261025_rerun/audio_comparison_summary.md`
içinde. Üretim manifestindeki tarihsel NSF hash'i `355c8960…`, diskteki önceki
NSF `2e89384e…`, yeni kaynak-olay adayı `5ed79521…`; bu build zinciri de
uzlaştırılmalı.

**Kaynak saatinden ses üretimi incelemesi:** ROM'dan üretilen NSF, CPU-cycle
APU yazımlarını ve DMC byte sırasını sağlayabiliyor; mevcut WaveHi renderer ise
DMC DMA/bit/DAC olay zamanlarını ve doğru frame sınırlarını da gerektiriyor.
libgme refill callback'leri bu DMA zamanlarının yerine geçmiyor. Tanı aracı artık
`--input-nsf` ile açık ROM-türevi NSF'i capture zaman çizelgesini okumadan trace
ediyor: 45.457 APU yazımı ve 104.187 DMC refill callback'i çıktı. Callback
zamanları DMA/bus-stall anı değil; aynı-cycle akış sırası da 284 çiftte
belirsiz. Bu çıktı mevcut WaveHi renderer'a FCEUX DMC girdisi olarak verilemez.
FCEUX'e eşdeğer kaynak-only PCM için cycle-clocked DMC buffer/shifter/timer/DAC
modeli gerekiyor. Tanı aracı ve çıktılar
`reference/diagnostics/audio/nsf_presenter_source_event_trace_20261025/` altında;
production WAV/runtime değişmedi. Ayrıntı
`reference/diagnostics/audio/rom_source_nsftowavehi_bottleneck_20261025.md`.

**BG08 üst kaydırma — kaynak izine dayalı runtime düzeltmesi:** Frame 1088'de
FCEUX `$A086/$A08B/$A091` üzerinden PPUCTRL `$88` ve PPUSCROLL `$00,$FF`
yazıyor; scanline 128'de `$2200` adresini geri yüklüyor ve alt bant için
`$00,$00` scroll'a dönüyor. Aynı girişli NewPPU CHR izinde satır 0, `$23E0`
tile `$55` prefetch'inden; satır 1, coarse-Y 31/fine-Y 7 taşmasından sonra
nametable satır 0'dan geliyor. Godot BG08 renderer'ı artık bu ROM scroll
durumuyla başlıyor; görsel çıktıyı sonradan kaydırmıyor.

Aynı girişli sekiz karelik doğrulama 1049'da RGB `%96,0270` → `%99,5622`,
1068'de `%95,5176` → `%99,0999`, 1088'de `%95,2913` → `%99,0999`, 1108'de
`%96,4421` → `%100`, 1201'de `%96,3086` → `%99,9707` ve 1522'de `%96,4144` →
`%99,9788` gösterdi. Kaynak izi, PNG'ler, eski/yeni metrikler
`reference/diagnostics/bg08_initial_scroll_validation_20261025/` altında.
Tam yakalama 1049–1524 bandındaki büyük kayma farkını giderdi. Frame 1088'de
553 piksel hâlâ farklı; OAM'de `$F8` ile gizlenmesi gereken negatif-X sprite
girdileri güçlü aday, ancak gizleme rutini/işlemi henüz ROM koduyla doğrulanmadı.
Alt raster/IRQ'nın satır içi ilk pikseli ve gerçek 2C02 zamanlaması da açık.

Hibrit OAM-Y düzeltmesi son `$890C` adımından sonraki yapay worker beklemesini
kaldırıyor; ilk kuyruk girdisi frame 3555'te hazırlanıyor, gösterilen OAM kayması
3555'te 47 ve 3556'da 48 oluyor. 210 karelik odak doğrulaması izole adayla
byte-byte aynı. Bu düzeltme önceki tam yakalamaya göre genel eşleşmeyi artırdı,
ancak BG08 üst bant ve sonraki sahne farklarını çözmedi. Frame 3652'de preset 0
yüklenirken `$79/$7C` RAM değerlerinin sıfırlanması da Godot modelinde eksik.

**Ses hazır değil:** Çalışma zamanındaki WAV ROM'dan üretilmiş NSF/driver
verisini kullanıyor; WAV manifestindeki çoklu cue kimlikleri ve mutlak kareleri
halen RAM `$0700` yakalamasından türetiliyor. Yeni tanılama betiği mevcut
ROM-komut sunucusunu 0–4661 karelerinde yürütüp 12 `$ED` ses komutunun hem
kimliğini hem kare sınırını RAM yakalamasıyla eşleştirdi; frame 4661'deki `$01`
ise ayrı `$8048` başlık-stop olayı olarak ayrıldı. Ancak sunucunun başlangıç,
EC kayıt/stall, F8 dönüş ve döngü fazı hâlâ yakalama dayanakları taşıyor; bu
tanılama üretim WAV'ini yeniden kurmadı veya değiştirmedi. Tek başına `$58` cue denemesi FCEUX ile örnek
eşleşmesini doğrulamadı (ilk 24.000 örnekte en iyi korelasyon `0,89923`, yaklaşık
4,2 kare erken). WaveHi tanı render'ı native FCEUX post-filter PCM ile tam
eşleşse de yakalanmış APU yazım/DMC zamanlarını kullandığından bağımsız runtime
kanıtı değildir. Mevcut Godot WAV'i birebir müzik doğrulaması sayılmamalı.
Manifestte kaynak NSF SHA-256'sı `355c8960…` olarak kayıtlı; aynı yoldaki mevcut
NSF dosyası `2e89384e…` hash'ine sahip. WAV'in kendi manifest checksum'ı
eşleşiyor, fakat WAV'i üreten kaynak build'in izlenebilirliği bu nedenle henüz
tekrar üretilebilir değil. Manifesti sessizce değiştirme; kaynak/build zinciri
ve ses yeniden karşılaştırılmadan runtime WAV'i yenileme.

Kaynak olay karşılaştırma aracı ve raporu `tools/diagnostics/export_cold_start_ed_source_events.gd`
ve `reference/diagnostics/audio/cold_start_ed_source_event_export_20261025.md`
altında. JSON doğrulama dökümü `/tmp/cold_start_ed_source_events.json`
konumunda, SHA-256 `9edc8cd78410a38f385c52e30e90651c540a829f3deb1db701cd90f5a4ebea75`.

Ses tarafında, ROM CPU-hook çevrimlerinden üretilen gölge frame-sequencer
çizelgesi başlangıçtaki 18.598 olayın ardından stop kuyruğundaki 123 olayı daha
FCEUX ile cycle, hook, PC ve sayaç-yenileme durumu bazında eşleştirdi. Tam
18.721 kaynak-gölge olayını kullanan tanı WaveHi çıktısı, 3.442.925 örneğin
tamamında native FCEUX post-filter PCM SHA-256'sıyla aynı: `445afa...`.
Böylece önceki stop-kuyruğu ayrışması, gölge çizelgesinin erken bitmesinden
kaynaklanıyordu. Ancak render hâlâ FCEUX yakalamasından alınan APU yazım
zamanlarını, kare-cycle aralıklarını ve DMC zamanlarını kullanıyor; bu sonuç
bağımsız Godot ses üretimini doğrulamıyor ve runtime WAV değişmedi. Kanıtlar:
`reference/diagnostics/audio/shadow_frame_sequencer_live_execution_20261025.md`
ve `reference/diagnostics/audio/shadow_wavehi_native_pcm_full_compare_20261025.md`.
ROM'dan üretilmiş NSF ile capture kullanmadan tek başına `$58` müzik cue'su da
çalındı. Bu libgme denemesi FCEUX PCM'sinin ilk 24.000 örneğinde `0,89923`
korelasyon verdi ve en iyi hizalama yaklaşık 4,2 kare erken çıktı; benzer
melodiyi doğruluyor ama özgün zamanlama/tını eşleşmesini değil. Kaynak sunucu
12 olayın kimlik/karelerini yakalama ile eşleştirmiş olsa da, WAV manifesti ve
runtime WAV hâlâ RAM `$0700` tabanlı event export'undan geliyor; kaynak sunucu
henüz bu üretim çizelgesinin yerine bağlanmadı. Eksikler
`reference/diagnostics/audio/source_only_track58_gap_audit_20261025.md` içinde.

Hedef tamamlanmadı. BG08 OAM/scroll, BG0B `$007B` reseti ve `$6E` runner
overflow düzeltmeleri doğrulandı; `$6E` loop penceresinin 37/37 karesi tam. A2
ortak OAM düzeltmesinden sonra 2367–2415 görünür alanı 49/49 tam eşleşiyor. EC
`$04` FC bekleme düzeltmesinde 2367–2594 aralığındaki `$0652/$0653`, paket
baytları, öznitelikler ve palet 228/228 karede eşleşiyor; görünür karelerin
218/227'si tam, kalan farklar y=0 overscan satırında. Takip düzeltmesi uzun
komut beklemelerinde EC sayacını tutuyor; 2680/2682'deki eski 61-piksel fark
kapanmış durumda.

Güncel OSD-maskeli görünür karşılaştırmada 4.673/4.693 kare tam; 20 karede en az
bir farklı piksel var. Kalanlar: 3523, 3525, 3527, 3536, 3547, 3551, 3555, 3560,
3561, 3564, 3571, 3575, 3576, 3583, 3594, 3601, 3603, 3635, 3645, 3649. On sekiz
karede 1–5 piksel farkı küçük sprite bölgelerinde kalıyor. F8 frame 3601'deki
99 piksel için FCEUX `$2000/$21C0` raster yazıları line 21/231'deyken Godot olay
üretmiyor; frame 3603'te `KICK OFF` glyph üst çizgisi FCEUX y=231, Godot y=238.
Tam tablolar ve güncel Godot kareleri
`reference/diagnostics/opening_runtime_full_20261026_post_hidden_tail/` altında.
Bu karşılaştırma kare içi PPU zamanlamasını veya açılışın tamamının birebir
olduğunu kanıtlamaz.

Güncel F8 izinde frame 3601 Godot raster olayı üretmiyor; FCEUX `$2000` ve
`$21C0` yazılarını sırasıyla line 21 ve 231'de yapıyor. Kare 3602 model/source
satırları 9/219 ve 16/226; kare 3603 18/224 ve 11/217; kare 3604'teki 13/215
satırları eşleşiyor. Önceki model frame 3603 `$21C0` yazısını doğru line 217'ye
koysa da yazı yine y=238'de kaldı; bu nedenle y=231 farkı tek başına yedi satır
olay kaydırmasıyla çözülemez. Kare 3601'deki 99 yanlış piksel ROM CHR'den opak
sprite renkleri; OAM önceliği `$20–$23` ve bir-kare DMA latch'i olası açıklama,
ancak `$4014` kaynak sayfası izi eksik. Ayrıntılı karşılaştırma ve gerekli
izler `reference/diagnostics/f8_visible_crop_audit_20261025.md` içinde.

Ses tarafında production WAV hâlâ yakalama tabanlı cue çizelgesine bağlı. ROM
NMI→sound-driver PLAY iziyle seed-1 cue fazı kaynak yolundan çıkarıldı: ilk APU
yazımı FCEUX'ten 1.221 cycle erken (eski seed-3 aday 60.781 cycle erken), 45.450
APU yazımı sırası ve 903 DMC yazımı aynı. Ancak seed-1 WAV dalga biçimi
korelasyonu yalnız 0,0194; cue event kareleri hâlâ bazı capture anchor'ları
içeriyor. Bu tanı adayı production WAV'e alınmadı; tam kaynak-zamanlı APU/DMC
çizelgesi ve örnek dalga biçimi eşleşmesi açık.
Script loop fazı artık sabit 4.199-kare varsayımından değil ROM'un
`FE $20 $A0` dispatch'inden türetiliyor; faz-8 başlangıç scheduler anchor'ı
korunuyor ve 12 `$ED` olayının yakalama-oracle imzası aynı. Bu düzeltme mutlak
başlangıç/EC/F8 zamanlarını çözmüyor ve runtime WAV'i değiştirmedi. Ayrıntı:
`reference/diagnostics/audio/source_loop_phase_from_fe_20261025.md`.
`reference/diagnostics/bg08_upper_raster_yplus1_poc_20261025.md`
tarihsel görsel POC'sini içerir; güncel runtime BG08 düzeltmesi ROM scroll
kayıtlarına dayanır.
Kodun kaynak kare hızı `60.0988` NES FPS olarak ayarlı; bu ayar tek başına canlı
pencerenin gerçek zamanlı hızını kanıtlamıyor. Son tam yakalama aracı 4.693 kareyi
712,9 saniyede manuel olarak aldı; bu süre normal oynatma hızı ölçümü değildir.
Godot Project Manager'daki eski `GodotRemake` kaydı da geçersiz; gerçek proje
`project.godot` dosyasının bulunduğu bu dizinin kökünde.

**25 Ekim 2026, güncel Godot başlık kontrolü:** Godot 4.7.2 ile mevcut proje
kopyasında `verify_title_cursor_controls.gd` başarıyla çalıştı: başlangıç
imleci `KICK OFF`; klavye ve gamepad Up/Down/Select iki seçenek arasında
geçiyor; Start seçimi onaylamıyor. `verify_main_opening_title_handoff.gd` de
ana sahneyi kaynak frame 4692'de görünür başlık menüsüne ulaştırdı; geçiş kuyruğu
tamamlandı, ilk seçim `KICK OFF` kaldı. Bunlar giriş ve geçiş durumunu doğrular;
açılışın tüm karelerinin güncel kodla görsel eşleşmesini veya ses örneklerinin
birebirliğini doğrulamaz.

**25 Ekim 2026, önceki kodla alınan tam açılış ölçümü:** 0–4692 karelik,
sessiz yakalaması 4.693/4.693 kareyi tamamladı; FCEUX ekran kayıtlarına ortalama
`%98,9474` RGB ve `%89,0615` önplan-birleşim eşleşmesi verdi. 2.622 kare RGB'de
tam eşleşti; başlık endpoint'i 4662–4692 aralığında 31/31 tam eşleşti. Ham
karşılaştırma ve temas sayfası
`reference/diagnostics/opening_runtime_full_chunks_20261025_161258/README.md`
içinde. Bu tam yakalamadan sonra üç kaynak-kodlu düzeltme yapıldı:

- BG03 portresi `$75` için `120 - $007A` ters-kamera dönüşümü ve ROM X-wrap
  işareti eklendi. Kareler 847–850 ve mevcut `$77` kontrol aralığı 2147–2156
  FCEUX ile 14/14 karede RGB ve önplan pikselleriyle eşleşiyor.
- Animasyon `$7D` için bank-10 `$A1CA` F1/F7 dizisi ve bank-0 `$975B` Q8.8
  bütünlemesi eklendi. Kareler 2438–2465'te ortalama RGB eşleşmesi `%95,33`'ten
  `%99,93`'e, önplan eşleşmesi `%90,76`'dan `%99,86`'ya çıktı; kalan pikseller
  oyuncu dışındaki küçük bir alanda.
- Kupa paleti `$FB 01 0D` ile seçilen `$09` kaynağına, `$D3A0`'a, `$E9 → $997E
  → $9ADA` yolu üzerinden bağlandı. Kareler 2940, 2953, 2968 ve 3000 RGB'de
  `%99,58`'e, önplan eşleşmesinde `%92,14`'e çıktı. Kare 3508 RGB'de `%98,12`
  eşleşiyor; daha sonra bunun renk/CHR değil OAM-Y gösterim fazı olduğu belirlendi.

Bu ölçümler `portrait_75_camera_motion_gap.md`, `foreground_7d_motion_gap.md`
ve `cup_palette_selector_trace.md` içinde kayıtlıdır. Üç düzeltmeden sonra tüm
0–4692 aralığı bu not ilk yazıldığında henüz yeniden yakalanmamıştı;
`%98,9474` / `%89,0615` genel ortalamaları o önceki koda aittir. Frame 0–50
yeni kodla yeniden üretildi ve eski Godot
çıktısıyla piksel piksel aynı; dar kontrol
`reference/diagnostics/startup_scheduler_scan_20261025_gui/README.md` içinde.

**25 Ekim 2026, sonraki tam-giriş yakalaması (F8 OAM-Y düzeltmesinden önce):**
Güncel Godot koduyla 0–4692 aralığının 4.693 karesinin tamamı alındı ve
FCEUX'in aynı girişli ekran indeksine karşılaştırıldı. RGB ortalaması `%99,5380`,
önplan-birleşim ortalaması `%96,6818`; 2.778/4.693 kare tamamen aynı çıktı.
Başlık 4662–4692 aralığında 31/31, 4000–4499 aralığında 500/500 kare tam
eşleşti. En zayıf RGB karesi 1088 (%95,2913); esas geniş artık fark 1000–1499
aralığındaki BG08 sahnelerinde. Ölçüm ve tam aralık tablosu
`reference/diagnostics/opening_runtime_full_chunks_20261025_164319/README.md`
ve `all_frame_metrics.csv` içinde. Bu ölçüm, aşağıdaki F8 OAM-Y düzeltmesinden
önceki çalışma kodunu kapsar.

**25 Ekim 2026, F8 OAM-Y görünürlük fazı:** ROM `$A4C0` döngüsü her `$890C`
artışından önce `$9FA8($01)` bırakımı yapıyor; 64 Y baytı frame 3555'te son
artışı alıyor, `$17` arka plan geçişinde sıfırlanmıyor ve frame 3966'ya kadar
korunuyor. `$9B7F` bunları frame 3967'de `$F8` ile gizliyor. Godot'taki önceki
OAM-Y gösterim düzeltmesi her karede önceki gölge değerini çiziyor.
Odaklı Godot/FCEUX karşılaştırması
3488–3570 aralığında RGB ortalamasını `%98,8942`'den `%99,9901`'e, önplan
eşleşmesini `%55,7097`'den `%99,6030`'a çıkardı; tam RGB kareleri 28/83'ten
70/83'e yükseldi. Kareler 3500–3515 ve 3553–3554 artık tam eşleşiyor; 3555 ve
3560'ta küçük artık farklar sürüyor. Tam yakalama sonrası inceleme, önceki
build'de Godot temizliğinin frame 3968'e kaldığını (ROM: 3967) ve frame
3620'de `$79/$7C/$44` sayaçlarının `22/68/68` olduğunu (ROM: `23/66/66`)
gösterdi. Worker beklemesi/kuyruk kenarı düzeltmesi ana koda alındı ve 210
karelik odak doğrulaması izole adayla piksel piksel aynı. 51 adımlı hareket
döngüsü 3601–3651 RAM değerlerinde 51/51 eşleşiyor; preset 0 yüklenirken
`$79/$7C`'nin frame 3652'de sıfırlanması hâlâ modellenmiyor. Kaynak baytları ve RAM taraması
`reference/diagnostics/f8_oam_y_shift_persistence_audit_20261025.md`, tam
yakalama farkları `reference/diagnostics/opening_runtime_full_chunks_20261025_170329/`
altında kayıtlıdır. Kayıt
`reference/diagnostics/f8_oam_latch_validation_20261025/` altında; bu lokal
iyileştirmeden sonra alınan tam ölçümün README'si toplam gerilemeyi de raporlar.

**25 Ekim 2026, başlangıç scheduler düzeltmesi:** Yeni sessiz FCEUX PC izi ilk
`$84E7` komutunun frame 8/cycle 224.570'te, ilk NMI'ın frame 9/cycle 238.264'te
çalıştığını gösterdi. Godot frame 8'de artık NMI uydurmak yerine ilk ready
worker için ayrı scheduler scan başlatıyor; gerçek NMI-ready release frame
9'da başlıyor. Bu başlangıç main-task akışının frame-sınırı modelidir, tam
6502 reset yürütümü değildir.

**25 Ekim 2026, tekrar oynatılan BG01 geçişi:** Güncel kodla alınan 4.693 karelik
tam yakalama, ikinci intro turunda frame 4579–4661 arasındaki siyah ekranı
buldu. Kaynak izine göre `$A02D F1 01` için loop phase 343 doğrudan çizim yolu,
F8 başlık CHR profilinin frame 3598'deki tek seferlik aktivasyonu ve tekrarlanan
script turundaki `$A031 F9 01` için `$8BB0` bir-sayım loader beklemesi Godot'a
aktarıldı. ROM trace F9'u frame 4541'de dispatch ediyor; sonraki `$9EED`
bırakımı frame 4542'de producer'ı yeniden yürütüyor. FCEUX ile doğrudan yapılan önceki
4541–4661 karşılaştırması RGB'de `%99,9497`,
önplan-birleşimde `%99,8931`; frame 4579 `%98,6328` RGB oldu. Aynı girişte
Start'ın ilk basıldığı frame 4661 için `$000D` raster worker slotunun Start
dalında ROM `$8040` `STA $0D` ile temizlendiği bulundu. `$9EED` slotları artan
sırayla taradığı için önce uyanan `$0001` ana döngüsü Start'ı işler ve `$000D`
slotuna sıra gelmeden raster görevini durdurur; bu sıra ROM baytları, scheduler
izleri ve frame sonu RAM ile destekleniyor, ancak tam CPU yazma çevrimi PC etiketiyle
yakalanmadı. Godot'un bir ek `$A2E8` adımını atladığı odaklı kare 61.440/61.440
pikselde eşleşiyor. Kanıt ve kareler
`reference/diagnostics/f9_release_credit_4541_4661_20261025/README.md` ve
`reference/diagnostics/start_input_raster_stop_4661_20261025/` içinde.

**25 Ekim 2026, A2 OAM görünürlüğü ve müzik kontrolü:** A2 animasyonunun ROM
Q8.8 konumundan üretilen 9-bit OAM koordinatları ve `$A8CE` DMA gizleme işareti
uygulandı. 2367–2415 aralığındaki 49 RAM/OAM kaydının 441/441 sprite tuple'ı
hem OAM gölgesi hem DMA kaynağıyla eşleşiyor; 2367–2385 aynı-giriş görsel
karşılaştırması `%98,08` RGB. Tam çağrı yeri ve `$4014` DMA fazı hâlâ açık.
Açılış müziği için ROM/NSF tabanlı yeni +2 kare ses başlangıç adayı 12 zarf
penceresinin 11'ini hizalasa da önemli parçalarda örnek korelasyonu düştü;
çalışma zamanı WAV'i değiştirilmedi. APU fazı ve ses dalga biçimi eşleşmesi
çözülmedi; karar izi `reference/diagnostics/audio/runtime_audio_source_backed_decision_20261025.md`.

**25 Ekim 2026, BG03 nametable sayfa biti:** ROM'un `$00,$BF,$08` kamera
worker'ı 256 piksel sayfa geçişinde `$7B=$01` üretirken Godot modeli yüksek
byte'ı kaybediyordu. BG03 PPUCTRL yazımı artık `$7B & 1` kullanıyor. 856–1024
ve 2163–2335 aralıklarındaki 342 kare yeni kodla tekrar yakalandı; RGB ve
önplan-birleşim eşleşmesi tüm karelerde `%100`, gerileme yok. RAM `$7A:$7B` ve
`$A086` PPUCTRL `$89` kayıtları iki aralık boyunca tutarlı. Kanıt:
`reference/diagnostics/bg03_ppuctrl_wrap_fix_full_20261025/README.md`.

**25 Ekim 2026, F8 son döngü fazı:** ROM `$A4FE` döngüsündeki ilk
`$9FA8($01)` bırakımı Godot'ta zaten kurulum-bırakımı olarak sayılmıştı; dönüş
yolunda yinelenen bir karelik bekleme kaldırıldı. 3952–3968 kareleri tam
eşleşiyor; 3601–3653 aralığının 47/53 karesi tam. Kalan altı karenin üçünde
başlangıç farkı var: 3601'de 1.324, 3602'de 261, 3603'te 354 RGB pikseli.
Diğer üç karede farklar 3635'te 2, 3645'te 1 ve 3649'da 2 pikseldir.
`reference/rom_extract/intro/f8_00_sequence_trace.md`, frame 3601'in miras
alınan IRQ fazını çözülmemiş işaretliyor; mevcut kanıt bu kare için yeni bir
ROM-kaynaklı düzeltme belirlemiyor. Başlangıç fazı ve küçük artık farkların
nedeni açık. 53 karelik
karşılaştırma `reference/diagnostics/f8_cluster_corrected_window/comparison.csv`
içinde; kare çıktıları aynı klasörde.

Son tam yakalama F8 OAM-Y görünürlük fazı düzeltmesinden önce alındı ve güncel
kaynak kodunun tamamının yeni ölçümü değildir. APU fazı ile 1000–1499 arasındaki
BG08 bileşimi ve kalan düşük eşleşmeli sahneler inceleniyor; hedef açık.

**25 Ekim 2026, BG01 ilk-satır kaydırması:** ROM'un `$A086-$A091` başlangıç
`$2005` latch'i, BG01 renderer'ına önceki-kare `$7A/$7B` RAM durumuyla eklendi.
Aynı girişte 500–749 arasındaki 250 kare yeniden yakalandı; RGB ortalaması
`%98,5134`'ten `%99,9927`'ye, önplan-birleşim `%96,9002`'den `%99,9848`'e çıktı;
her kare iki ölçütte de iyileşti. Kaynak ve karşılaştırma
`reference/diagnostics/bg01_initial_scroll_500_749_20261025/README.md` içinde.
Bu hedefli pencere sonucu tüm açılışı doğrulamaz.

**25 Ekim 2026, BG0B EC-stop düzeltmesi:** `$A1FB`'deki `EC FF`, aynı karede
`$A1FD` `EE` ile yapılan `$9953` sıfır dolgusundan önce üç bekleyen EC PPU
paketini iptal edecek şekilde modellendi. ROM PPU izinde bu 12 hücre temizlendikten
sonra tekrar yazılmıyor. Güncel Godot 2694–2938 yakalamasındaki 245 karenin
tamamı RGB ve önplan-birleşimde 100% exact; eski penceredeki 209 kare iyileşti,
36 kare aynı kaldı, gerileme yok. Kanıt:
`reference/diagnostics/bg0b_residual_2724_2730_ec_cancel_20261025/README.md` ve
`reference/diagnostics/bg0b_ec_cancel_2694_2938_20261025/`.

**25 Ekim 2026, önceliklendirilmiş hedefli doğrulama:** Kapsam soğuk
açılıştan `KICK OFF` / `CONTINUE` başlık menüsüne kadardır; sonraki hikâye,
maçlar ve oyunun diğer ara sahneleri bu milestone'a eklenmeyecek. Her iterasyonda
4.693 kareyi yeniden yakalamak yerine yalnız değişen ve düşük eşleşmeli aralıklar
karşılaştırılıyor. FD-origin imleç eşitlemesi ve signed `$E3` rewind
düzeltmelerini içeren temel karşılaştırmaya BG0B 2694–2938, BG09 2018–2117,
F8 3550–3600, BG07 1534–1555/1755, BG0B 35 seçili scroll karesi ve BG0A
2367–2373 ilk-satır lag karşılaştırmaları eklendi; sonrasında BG07'nin +20
dünya-tile yerleşim düzeltmesi için 1535–1555 tekrar yakalandı. Güncel birleşik
BG01/BG0B güncellemelerinden önceki son birleşik ölçümde RGB eşleşmesi
%97,351, önplan-birleşim eşleşmesi %87,779; başlangıç
kareleri 0–8 çıkarılıp FCEUX `Power on` OSD alanı 9–139 maskelenince oyun
görüntüsü %97,365 RGB / %87,751 önplan eşleşiyor. Hesap
`reference/diagnostics/opening_combined_metrics_20261025_after_bg07_targets.json`'da.
Bu, yeni düzeltmeleri içermeyen ve son kaynak koduyla baştan alınmış olmayan
4.693 karelik yeni çekim değildir;
birleştirilmiş yüzdeler genel ilerleme ölçüsüdür, birebirlik kanıtı değildir.
OSD Godot runtime içeriği değildir.

**Süreyi kısaltma planı:** paralel işler yalnız birbirinden bağımsız kök
nedenlere ayrılır; her iş dar kare aralığında kaynak kanıtı ve Godot/FCEUX
karşılaştırması üretir. BG01 500–749 ve BG0B 2694–2938 güncel kodla hedefli
olarak doğrulandı. Tam güncel 0–4692 karelik yakalama sırada; ses eşlemesi ve
source-timed APU çıktısı açık. BG03 2147–2156
ve güncel BG07 hedefleri
1535–1549, 1559, 1560–1564, 1600, 1610–1615 ve 1755 exact. Bu sırayla dar kanıt/karşılaştırma
yapılıyor. Frame 2369 için önceki kamera-durumunu kullanan kaynak destekli
düzeltme uygulandı ve yalnız 2367–2373 tekrar karşılaştırıldı. Trace-replay
modundaki `fhcnt` farkı tek başına runtime ses hatası sayılmıyor. Her düzeltmeden sonra yalnız etkilediği kısa aralık
yeniden yakalanır; geniş tam-açılış yakalaması ancak hedefli değişiklikler
birleşince yapılır. Dış kaynak taraması yalnız belirli bir çözülmemiş byte veya
handler sorusuna cevap verecekse yapılır.

BG07 ROM tile placement'ının `$2114` origin'inden 20 dünya tile'ı ileride,
ikinci nametable'e yazıldığı PPU/RAM snapshot'ları ve ROM paket adresleriyle
doğrulandı. Loader bu +20 offset'i uygular. Önceki-kare OAM latch düzeltmesinden
sonra 1535–1555 penceresi iki odaklı yakalamada tüm 21 kare için %100 RGB exact
çıktı. BG07 sprite render'ı OAM'ın önceki-kare latch'ini
kullanacak şekilde düzeltildi; frame 1560–1563, 1600 ve 1755 de yeni kodla
61.440/61.440 RGB pikselde eşleşti; 1755 metin/portre farkı kapandı. Frame
1535 siyahı ve frame 1548'in 6-piksel cyan şeridi doğru eşleşiyor. İlk yakalamadaki scheduler
uyarısı yeni 1600/1755 çekiminde tekrarlanmadı; aynı çağrı yığını live runtime
ve capture yolunda olduğundan olası runtime uyarısı olarak izleniyor, düzeltme
için kanıt yok. Kanıtlar `reference/diagnostics/bg07_world_offset_fix_20261025/README.md`
ve `reference/diagnostics/bg07_world_offset_fix_checkpoints_20261025/` içinde.
BG0B'nin eski 2694–2938 penceresi %89,01'den %92,16 RGB'ye; sonraki 35 seçili
karelik kaynak-scroll denemesi %91,94'ten %96,33'e çıkmıştı. Bu ara sonuçlar
artık güncel değil. ROM byte/layout kanıtıyla eklenen +20 dünya-tile yerleşimi,
önceki-kare OAM latch'i ve `$EC FF` bekleyen paket iptali sonrasında 2694–2938
aralığının tüm 245 karesi yeni kaynakla yeniden yakalanıp RGB/önplan ölçütlerinde
100% eşleşti. `$A086–$A091` kamera yolu ve `$A178–$A18A` raster olayları için
kanıt `reference/diagnostics/bg0b_scroll_raster_test_20261025/README.md`,
`reference/diagnostics/bg0b_source_transitions_20261025/README.md` ve
`reference/diagnostics/bg0b_ec_cancel_2694_2938_20261025/README.md` içinde.
F8 başlık yükleyicisinin seçtiği `$17` kaydı artık aktif PPU profilinden ayrı:
loader frame 3555'te başlıyor, son paket/RAM `$7C/$7E` frame 3597'de, aktif
CHR profili frame 3598'de değişiyor. 3550–3600 ana-sahne kaydı bu RAM/renderer
sınırını doğruladı; ortak seçili görüntü karelerinde piksel değişmedi çünkü
geçiş siyah. F8 penceresi, BG09 ve BG0B taze pencereleri artık birleşik skora
katıldı; ayrıntı
`reference/diagnostics/f8_chr_profile_handoff_20261025/README.md` içinde.
Frame 13 logo sprite'ı OAM latch sınırında görünür; kareler 2376–2385
%97,20/%94,36; Tecmo logo döngüsü 4207–4481 ve title/geçiş 4662–4692 tam
eşleşiyor. BG03 kamera/OAM ve sayfa eşlemesi de kaynak izinden aktarıldı:
`$00,$BF,$08` worker'ı `$7A` kamera adımını ve animation `$77`'nin ters
yönlü OAM X/culling dönüşümünü sürüyor; PPU yazımı `$2508` olduğundan BG03
paketleri +32 tile ile ikinci nametable'e yerleşiyor. 2147–2156 kareleri tam
RGB/foreground exact. Önceki birleştirilmiş taban çizgisinde BG0B 2726–2729 ve
BG07'nin kısa 1550–1555 raster geçişi düşük görünüyordu; güncel hedefli
yakalamasında BG07 1535–1555 ve BG0B 2724–2730 exact oldu. BG0B 2694–2938
geniş penceresi için EC-stop düzeltmesi sonrası karşılaştırma sürüyor. Önceki
BG0B 2939–3597 penceresi ortalama %97,83 RGB exact. Frame
2369 için kaynak destekli önceki-kamera-durumu düzeltmesi sonrasında RGB
eşleşmesi %68,40'tan %97,96'ya, 2370 karesi %96,27'den %97,69'a çıktı;
2371–2373 değişmedi. NewPPU izi iki karenin y=0–127 fetch durumunun aynı
olduğunu ve runtime'ın aynı-kare kamera durumunu erken aldığını gösterdi.
y=129 IRQ yazılarının RGB pikseli değiştirmediği ayrıca doğrulandı. Kalan
farklar açık. Ayrıntı
`reference/diagnostics/frame2369_upper_first_line_trace_20261025/README.md`
ve `reference/diagnostics/frame2369_irq_split_dot_audit_20261025.md` içinde.
Bu yalnız görüntü doğrulamasıdır;
Dummy ses sürücüsüyle sessiz yapıldı. Kayıt
ve ölçüm `reference/diagnostics/opening_runtime_recapture_20261025_cursor_origin/`
altında; 4.038 viewport okuması ve 655 değişmeyen kare yeniden kullanımı.
Kaynak kapsamı ve sınırlar
`reference/rom_extract/intro/frame_capture_coverage_and_mapping_status.md`
içinde. Metal viewport yakalayıcısı çizimden sonra ek işleme karesi bekliyor.

Frame 3000 için `$67` diyalog glifinin ROM akışı `$A23B` → RAM `$05E8` paketi
→ PPU `$2269` → CHR offset `$0670` yolu doğrulandı. PC etiketli iz, frame
2908'de FD task'ının `$885D→$8887→$84D7` yoluyla bank-0 `$84DB/$84E3`'ün
`$4F/$50=$2249` değerlerini `$51/$52`'ye kopyaladığını gösterdi; Godot bu FD
origin'i artık kullanıyor. Hemen arkasındaki `$E3`, `$53`'ü `$2249`'dan
`$2246`'ya indirir. Godot'un eski sıfır kırpması kaldırıldı: frame 2908 queue
artık `$2246–$2251` aralığını izliyor ve frame 3000'de Godot PPU `$2269=$67`,
ROM ile aynı. 2904/2908/2938 hedefleri %100 RGB idi. BG0B'nin ortak
`$A086/$A160` PPU olayları ve başlangıç R0/R1 değerleri artık kaynak
renderer'a bağlı; aynı kare 130'daki R0/R1 yazımları için dot 146/197
kullanımı örnek yakalama noktalarıdır, her karedeki gerçek dot henüz bağlanmadı.
Etkilenen 2939–3597 aralığının 659 karesi yeniden karşılaştırıldı: pencere
ortalaması %97,83 RGB (önce %92,47), 552 kare iyileşti, hiçbiri gerilemedi,
107 aynı kaldı. Birleşik tam-açılış oyun-piksel skoru %96,86 RGB / %85,57
önplan oldu. CHR fetch renk kenarları ve dot hassasiyetli per-frame yazımlar
hâlâ açık. Kanıt ve sınırlar
`reference/diagnostics/opening_runtime_full_1792924153/frame_2758_gap_audit.md`
içinde; signed E3 için
`reference/diagnostics/text_cursor_reset_runtime_20261025_150000/e3_cursor_offset_audit.md`.

BG0B sahnesinde kamera ve sprite hareketinin kaynak yolu çözüldü: ROM kaydı
`00 3F 08` ortak `$8BD8` worker'ına gider; `$7C` animasyonu kamera-takip bayrağı
ile `$E8=-$47` adımını her sprite X'ine uygular. X taşması iç öznitelikteki
`$04` işaretini değiştirir; OAM kopyalayıcısı `attr & $0C` doluyken Y=`$F8`
yazar, işaret kalkınca sprite'ı görünür konuma alır. Kaynak RAM'deki görünür
sprite sayısı Godot'un ROM-derived modelinde 2694/2700/2710/2713/2714/2715/
2720/2722 karelerinde sırasıyla 0/0/14/33/38/40/40/40 olarak doğrulandı.
Godot görüntüsü bu sahnede belirgin biçimde iyileşti ama hâlâ kare eşleşmesi
tam değil; bu çalışma tüm intro veya PPU dot zamanlamasının çözüldüğü anlamına
gelmiyor. Baytlar, iz ve karşılaştırma:
`reference/rom_extract/intro/bg0b_camera_oam_trace_20261025.md` ve
`reference/diagnostics/ram_oam_write_trace_20261025_121710/`.
Bu karşılaştırma karelerinden sonra çizici kod incelemesinde her sprite'ın X
koordinatında 8 bitlik OAM sarımının eksik olduğu bulundu ve düzeltildi. Yeni
tam yakalama bu düzeltmeyi içeriyor; kaynak kareleri 2694–2722 ortalama %92,05
RGB / %6,03 önplan veriyor. OAM sayıları eşleşse de bu bölümün görsel
kompozisyonu hâlâ doğru değil.

Godot yakalayıcısına görünür çizim durumu anahtarı eklendi: aynı durumdaki
ardışık kareler için viewport'u yeniden okumuyor, fakat her kareyi yine
karşılaştırıyor. 10 karelik örnekte 1 viewport okuması ve 9 görüntü yeniden
kullanımı oldu; 10 çıktı da önceki renderer görüntüleriyle piksel piksel aynı.
Ek olarak sprite pozları, ortak OAM resmi ve MMC3 girdileri değişmediğinde
gereksiz yeniden çizim yapmıyor.

Ardından saha rasterında eksik bir ROM yazımı bulundu: satır 133'teki
`$2006=$2200` yüklemesini `$A187/$A18A` adreslerinden gelen `$2005=$00,$00`
sıfırlaması izliyor. Godot olay listesine bir sonraki etkin satırda bu sıfırlama
eklendi. Kare 502, 506, 758 ve 800 için tam-kare RGB eşleşmesi %98,27–98,89;
satır 128–138 artık dört karede de %100, satır 139–226 %99,94–100. Bu hedefli
kontroldür; ardından tüm 4.693 kare yeniden karşılaştırıldı ve ortalama RGB
%94,55'ten %95,81'e çıktı, gerileyen kare olmadı. Kanıtlar
`reference/diagnostics/raster_fine_x_reset_20261025/`
içinde; tüm açılışın birebir olduğu anlamına gelmez.

Yeni Japonca/Çince/Türkçe aramalar açılışın tamamını çözen kare→komut→PPU/APU
izini bulmadı. En kullanışlı dış kaynak, bazı ROM rutinlerini bayt eşlemesiyle
kontrol etmeye yarayan anotasyonlu 6502 disassembly; Hack CT2 ve bölgesel
rehberler editör, veri kataloğu veya sahne düzenleme ipuçları. En hızlı sonraki
adım yeni bir genel tarama değil: mevcut 551 komut/34 tekrar izinin çözülemeyen
yardımcı ve NMI yollarını izlemek; görüntü farkı olan sahnelerde scanline/dot,
CHR fetch ve OAM/öncelik izlemesi almak; ses için DMC timer/buffer/DAC fazını
ROM verisiyle tamamlamak. Kaynak sınıfları ve doğrudan bağlantılar
`reference/rom_extract/intro/online_reverse_engineering_resources.md` içinde.
Müzik komutlarının sırası ROM izinden doğrulandı; dış NSF/gamerip kaynakları
yalnız parça adı ve dinleme referansı veriyor, bu ROM revizyonu için kareye
hizalı APU yürütümü sağlamıyor. ROM `$01` stop isteğini frame 4661'de veriyor;
frame 4662'de `$4015=$0F` DMC fetch'lerini durdururken triangle kanalını etkin
bırakıyor. Pulse/noise gain sıfırlanıyor, fakat kısa kalan sayaçtan sonra ROM
yazıları ve FCEUX kodundan kurulan model triangle DAC adımını 21 olarak tahmin
ediyor; bu ham izde doğrudan örneklenmiş bir değer değil. DMC DAC latch'i
`$60`'ta kalıyor; modelin WaveHi TND girdisi üçgen 15 + DMC 96 oluyor.
FCEUX'ün 1.024-tap FIR ve `SexyFilter` geçmişiyle birlikte çıktı frame 4679'a
kadar sürüyor. ChannelBC tabanlı kaynak prototipi kuyruğun şeklini yüksek
korelasyonla izliyor, fakat stop sonrası ses %17,6–18,1 daha yüksek ve kare/DMC
zamanlamasını FCEUX ölçümlerinden tekrar oynatıyor; bu yüzden runtime'a alınamaz.
Frame 4661 sonundaki trace-replay karşılaştırmasında önceki 0/1025 kanal
sonucunun yanlış örnek penceresi/gain kaynaklı olduğu bulundu: doğru hizalanmış
1025 örnekte beş kanal, WaveHi, FIR fazı ve iki `SexyFilter` accumulator'ı tam
eşleşiyor. Bu iz-oynatım kolunda `fhcnt` alanı güncellenmediğinden +16.032
görünmesi stale-state farkı; ROM clock kolu ise `fhcnt=341928` değerini
eşleştiriyor, fakat triangle adımı 8 yerine 12 ve triangle/WaveHi/filtre
checkpoint'i hâlâ farklı. Clock kolundaki ilk frame update aday cycle 7458,
FCEUX hook cycle 7459. Başlangıca +1 cycle eklemek bunu hizalıyor; fakat
`$4017=$40` resetinden sonra cycle 126909 olayı FCEUX'un 126912 hook sınırından
üç cycle önce geliyor. Yalnız bu olayı hook sınırına erteleyen geçici deneme
frame-4661 triangle/WaveHi/filter farkını değiştirmedi. İzlerdeki update cycle
ve APU yazılarıyla yeniden kurulan ilk triangle-state farkı cycle 8,404,734:
aday `TriCount=15` yaparken kaynak model 0'da kalıyor; FCEUX frame-update hook'u
8,404,737'de, PC `$C46F`'te çalışıyor. ROM'da `$C46F` beş-cycle `LSR $3B`;
FCEUX sound hook'u bu talimatın sonunda çalıştığından eşik ile hook arasında
üç cycle var. Yalnız bu olayı talimat sonuna erteleyen deneme endpoint'i
düzeltmedi. Yeni uzun hook izi, `$4017` resetinden ilk triangle ayrışmasına
kadar 1.112 frame-sequencer sınırını PC/opcode/cycle bilgisiyle kaydediyor ve
bu aralıkta hiç DMC DMA olmadığını doğruluyor; ilk DMC okuması daha sonra,
cycle 10.905.284'te başlıyor. Dolayısıyla ilk triangle farkı DMC'nin eklediği
çevrimlerden kaynaklanmıyor. FCEUX hook başı/sonu farkını ve DMC okuma çevrimini
raporlayan küçük tanı yaması ile 8.404.000–8.405.000 talimat penceresi
belgelendi; `$C46D` sonrası sayaç 96 kalıyor ve `$C46F` beş-cycle hook'unda
`96→−144` ile güncelleniyor. İlk DMC enable cycle 10.905.284; sonraki iki DMC
byte fetch'i FCEUX'te dört ek cycle alıyor. Bu sınır ilk ayrışmayı açıklar,
ancak tüm instruction/NMI/DMC zaman çizelgesini ROM yürütümünden üretmez; ara
`TriCount`, `tristep` ve sayaç durumu pinned FCEUX sayaç kodundan kuruluyor.
Hiçbir tek checkpoint tam açılış sesini doğrulamaz; runtime WAV değişmez. Ayrıntı
`reference/rom_extract/audio/post_stop_filter_tail_source_trace_20261025.md`
ile `reference/diagnostics/audio/rom_source_wavehi_checkpoint_compare_20261025/dmc_hook_clock_followup.md`
`reference/diagnostics/audio/start_tail_audit_20261024.json` ve
`reference/diagnostics/audio/fceux_hook_cycle_delta_capture_audit_20261025.md`
içinde. Sonraki adım FCEUX'ten alınan kare/hook izini runtime çizelgesi diye
kopyalamadan, ROM yürütümünden instruction-boundary frame-sequencer modelini
kurup ara APU/triangle/DMC checkpoint'lerini yeniden karşılaştırmak.
Stop-tail state ölçümünün kapsamı
`reference/diagnostics/audio/stop_tail_minimum_state_checkpoint_20261025.md`
içinde.

**27 Ekim 2026, F9 scheduler doğrulaması:** ROM dispatch trace `$A031 F9 01`
komutunu source frame 4541'de kaydediyor; F9 içindeki `$8BB0` `$9FA8(A=$01)`
beklemesinden sonra `$9EED` bir sonraki release'te producer'ı frame 4542'de
yeniden çalıştırıyor. Frame-4542 RAM'deki `$0628=$39` ve dokuz kuyruk paketi bu
sırayla uyumlu. Kodda `$A031` dispatch anında release'i önden sayan koşulun
erken bir kareye yol açtığı yakalandı ve kaldırıldı; artık ilk `$A022 F9 00` ve
tekrarlanan `$A031 F9 01` yolları `$8BB0` beklemesini açıkça yürütüyor. Yeni
Godot yakalamasının 4577–4585 kareleri, 26 Ekim tam Godot yakalamasına RGB
piksel düzeyinde eşit. Bu regresyon kontrolüdür; yeni bir FCEUX yakalaması
değildir ve CPU/NMI alt-kare fazını bağımsız doğrulamaz.

**27 Ekim 2026, diyalog imleci:** ROM `$8678` F2 handler'ı yalnızca yazı hızını
`$55`'e yazar; F2 adreslerine özel `$2249` cursor reset listesi kaldırıldı.
Başlangıç cursor'ı worker kurulumu, sonraki sahneler FD'nin `$4F/$50 → $51/$52`
kopyası ve FC/E3 kendi ROM yollarından alıyor. 16 odak karesinde (379/380,
836/837, 1119/1120, 1551/1552, 1779/1780, 2143/2144, 2368/2369, 2711/2712)
yeni Godot çıktısı önceki tam yakalamayla piksel piksel eşleşti. Bu önceki
tam yakalama FCEUX'in görünür kareleriyle doğrulanmıştı; bu kontrol yeni bir
FCEUX PC izi üretmez. FD'nin her çağrı noktası ayrı ayrı cycle-tagged değildir.

Yeni bir görsel kök neden de çözüldü: F9 arka plan profili seçimi Godot field
renderer'ına profildeki ROM paletini hemen veriyordu; kaynak PPU ise F3 palet
paketini sonraki NMI'da işleyene kadar `$0F` siyahında kalıyor. Renderer artık
profil paletini değil o karede commit edilmiş PPU paletini kullanıyor. İlk geçişte
kare 342, 352, 362, 375, 378 ve 379 %100 RGB eşleşiyor; 380'de palet görünür
oluyor ve kare %97,79 eşleşiyor. Aynı kaynak akışı 1049/2369/4579 için kayıtlı;
frame-2369 üst raster farkı daha sonra önceki-kamera-durumu aktarımıyla
%97,96'ya yükseldi. Diğer sahne kompozisyon farkları sürüyor. Önceki tam-kare
ortalaması tarihsel baz çizgisidir; güncel birleştirilmiş ölçüm yukarıda.
Ayrıntı `reference/diagnostics/palette_commit_boundary_20261025/` ve tam kare
raporunda.

Hedef açık; ses ve tam görüntü zamanlaması henüz bitmedi.

**25 Ekim 2026, BG08 frame-1522 raster aktarımı:** ROM preset-01 ve
`$BA96` CHR seçim akışı Godot'a bağlandı; `F5 10` başlangıcı, frame başı
R0/R1 çiftini, `$2200` adres olayını ve `$A160/$A1CB` alt-bank geçişini
ROM-derived model yürütüyor. Renderer, her bit düzlemini FCEUX NewPPU'nun
scanline/dot fetch sırasındaki etkin banktan okuyor. Kaynaktan aynı girişle
alınan frame 1522'nin Godot RGB eşleşmesi %61,07'den %92,12'ye; önplan
eşleşmesi %32,40'tan %84,83'e yükseldi. Diyalog CHR bankı artık doğru; oyuncu
ve top konumu hatası ROM C1/82 ortak OAM'ı eklenerek düzeltildi. Yeni tam kare
yakalama frame 1522'de %96,41 RGB / %92,84 önplan eşleşmesi veriyor; tüm 2.563
opak sprite pikseli eşleşiyor, 64 OAM slotundan 63'ü doğrulandı. IRQ dot fazı kareler arasında değiştiği için
frame-1522 zaman kalibrasyonu tüm kareler için exact kabul edilmiyor. BG08
yüklemesi sırasında BG03 `$3A/$00` çiftinin korunması da Godot modeline bağlandı:
hedefli denetimde frame 1047 `$3A/$00`, frame 1048 `$40/$00` olarak doğrulandı.
Aynı karşılaştırmada frame 1050 RGB eşleşmesi %92,71 oldu; tam kare farkları
devam ediyor. Ayrıntı:
`reference/diagnostics/frame1522_dynamic_chr_gap_audit_20261024.md`.

**24 Ekim 2026, açılış geçişi düzeltmesi:** Frame 819'da `F4 05` palette
komutu artık dolu PPU kuyruğunu hata saymak yerine ROM `$9B28` kapasite kuralıyla
bekleyip yeniden deniyor. FCEUX frame-819 RAM'i `$0628=$3F`, `$0629=$20` ve
önceki F3 palet paketiyle kalan dört arka plan paketini gösteriyor; bu nedenle
NMI kuyruğunun boşalmasını beklemek kaynak davranışıyla uyumlu. Godot 4.7.2
headless kaynak izi artık frame 819'da durmuyor; frame 820'de BG03 paketleri
40/40'a ulaşıyor, frame 836'da F4 geçişi bitiyor ve frame 1522'de BG08 ile
`$C1/$82` animasyonları çalışır durumda. Sonra EA-clear ve sprite X-sarması
değişiklikleriyle 981 checkpoint aynı-girdi yakalaması alındı:
`reference/diagnostics/opening_runtime_sparse_1792874188/`. Önceki yakalamaya
göre tam RGB ortalaması %68.53'ten %70.26'ya yükseldi (201 kare iyileşti, 180
kare geriledi, 600 aynı); önplan ortalaması %28.11'den %27.84'e düştü.
Frame 1022, %59.91/%2.70'ten %92.45/%10.12'ye çıktı. Ancak frame 1522 hafif
gerileyerek %61.50/%34.52'den %61.07/%32.40'a indi. O karede oyuncu/top Godot'ta
sağ kenara kaymış, diyalog yazı karoları bozuk; ROM kaynaklı CHR denetimi,
frame içi bank değişiminin eksik olduğunu gösteriyor. Bu fark ve sınırlamalar
`reference/diagnostics/frame1522_dynamic_chr_gap_audit_20261024.md` içinde.

**25 Ekim 2026, frame-1522 CHR provenance izi:** Sessiz FCEUX 2.7.0 build'i
aynı girişlerle tekrar çalıştırıp `$2269` nametable adresini, tile ID'sini,
CHR düzlemlerini ve NewPPU çıktı hücresini tek izde birleştirdik. Bu, tek
diyalog tile'ı için kaynak hücre → CHR byte → FCEUX çıktı bloğu bağlantısını
kuruyor; tüm frame/piksel eşlemesini ve Godot görselini doğrulamıyor.
Tam ölçüm `reference/diagnostics/chr_plane_nt_trace_20261025/README.md` içinde.

Frame 1022'deki Tsubasa portresinin kesilmesi, ROM `$BC` X başlangıcını 8-bit
OAM koordinatına sarmadan negatif piksel olarak kırpan sprite renderer'ına
bağlandı; kaynak OAM'ın 39/39 tanımlayıcısı X/Y/tile/attribute alanlarında
eşleşiyor. X-sarması sonrası portre görünür hâle geldi ama tam kompozisyon
eşleşmiyor. Bu durum kaydı yazılırken frame 2034'te Godot'un pembe arka planı
eksikti; aşağıdaki BG09 devamı palet animasyonunu ekleyip kaynak durumuyla
karşılaştırıyor. Açılışın 4.693 PPU
ve RAM kaydı kare-sonu bellek durumudur; ayrı ekran klasöründe 981 ham görüntü
ve bunlara ait 981 `.uid` yan dosyası (toplam 1.962 dosya) vardır. Frame 1522
bus izi CHR banka geçişini gösteriyor. Yeni, sessiz ve aynı-girdili FCEUX
instrumentasyonu frame 1522'de 128–165. tarama çizgilerindeki 2.584 arka plan
CHR düzlemi okumasını adres, bayt, CHR bankı ve dot ile kaydetti; tüm baytlar
ROM CHR verisiyle eşleşiyor. Diyalog tile `$48` için 16 düzlem okumasının
tamamı bank 1'den (`$0480–$048F`) geldi ve ROM offset 1152–1167 ile eşleşti.
`$A1CB` R0 yazımından 13 dot sonra ilk bank-0 okuması görüldü. Bu, ilgili
iz penceresinde hangi CHR baytlarının okunduğunu çözüyor. Sabitlenmiş FCEUX
çizici kodu bir tile-0 fetch'ini `x=168–175,y=129`, `$0481` glyph okumasını
`x=72–79,y=152` çıktı bloğuna eşliyor. Yeni provenance izi nametable adresi
ve tile ID'sini de CHR okumalarıyla birlikte kaydediyor: `$2269`/`$48` hücresi
bank 1'den okunup FCEUX NewPPU'da `x=72–79,y=151–158` aralığına bağlandı;
line-130 bank-0 fetch'i ise ayrı `$2215`/`$00` tile'ı. Bu FCEUX yazılım
çizicisinin eşlemesidir; son fiziksel PPU shifter/renk geçişini veya tüm
ekranı çözmüyor. Ayrıntı `reference/diagnostics/chr_plane_nt_trace_20261025/`
içinde.
Presenter artık frame 2340'taki
ROM `$A1B6 F1 01` çağrısını aynı-kare `$9953` temizleme ve `$9860` ROM kaydı
yazımlarına dayanarak doğrudan çizim yolu olarak eşliyor. Önceki frame-3465
durması, text glyph'lerinin `$9B28` PPU kuyruğu kapasitesini doldurduğunda
ROM'un yaptığı release beklemesinin modellenmemesinden kaynaklanıyordu. Bu
kapasite beklemesi eklendikten sonra presenter'ın F8 öncesi dispatch'leri
`$A297 DF` frame 3213, `$A298 F4 05` frame 3453, `$A29A FD` frame 3469 ve
`$A29B F8 00` frame 3476 olarak hizalandı. Önceki frame-2682/3465 görsel
karşılaştırmaları güncel koda kanıt değildir; F8 için yeni raster modeli ve
aynı-kare karşılaştırma aşağıdaki güncel izde açıklanır.

**25 Ekim 2026 ek devam:** İlk multi-object `$A2` animasyonunun hareket
kayıt dilimi Godot'a eklendi. Presenter, bank-10 `$A50E` girişindeki F1
başlangıç/son konumlarını ve yalnız gözlenen `F7 29 00 00` / `F7 00 00 00`
komutlarını `$975B` Q8.8 güncelleme sırasıyla uygular ve `$A2` sprite origin'ini
kayıttan alır. RAM `$0588` ile OAM gölgesi `$04A8–$04CB` kaynak kare çapalarıyla
eşleşen değerler belgelendi. `$0240–$0263` DMA sayfasındaki Y=`$F8` gizleme ve
culling kuralı açık bırakıldı; aynı-girdi Godot OAM/raster karşılaştırması ve
launch kontrolü yapılmadı. Ayrıntı
`reference/rom_extract/intro/a2_motion_record_trace_20261025.md` içinde.

**24 Ekim 2026 ek devam:** İlk geçişteki `FB` komutlarının 13 ROM animasyon
kimliği (8D, 6E, 75, C1, 82, 76, 84, 77, C0, A2, 7D, 7C, 0D), giriş bankı,
kare tanımları ve örnek OAM sırası belgelendi. Kaynak-komut prototipi artık
her `FB` listesini ROM animasyon renderer'larıyla yeniliyor; ilk listedeki
nesne OAM önceliğini koruyacak şekilde öne çiziliyor. Tam OAM sınırı, beş
gizli/ekran dışı descriptor farkı ve nesne ömürleri açık. F7'nin canlı
`$0568` kaydı ve `$975B` ROM integrator'ı `rom_runner_motion_record.gd` içinde
ROM F1/F7 baytları ile timing verisinden çalıştırılıyor; aynı-girdi Godot OAM
ve raster karşılaştırması henüz yapılmadı.
`FC` için ROM kodu `$51:$52` tabanına `$0040` ekleyip `$53` sütununu tabana
döndürüyor; eşzamanlı RAM'de tespit edilen sekiz yeni satır başlangıcı ayrı
yakalama çapası olarak uygulanıyor, reseti F2'nin yaptığı iddia edilmiyor.
Post-FC yazıların NMI ve raster görünürlüğü doğrulanmadı. Dokuz ilk-geçiş `FD`
çağrısının temizleme boyutu/adresi, doğrudan ya da dört-NMI kuyruk yolu
belgelendi ve yakalama çapalı prototipe bağlandı. Ayrıntılar
`reference/rom_extract/intro/opening_fb_animation_coverage.md`,
`text_cursor_queue_trace.md` ve `fd_scene_clear_trace.md` içinde.

ROM-komut sunucusu için `scenes/opening_source_runtime.tscn` sarmalayıcısı
hazırlandı ve artık `scenes/main.tscn` buradan başlıyor. Sarmalayıcı ROM ses
sürücüsü/verisinden çevrimdışı üretilen tek WAV'ı çalıyor; Start girdisinden
sonra 30 kare siyah geçişle ROM-CHR başlık ekranını açıyor ve `KICK OFF` /
`CONTINUE` onayını bu dilimde kapalı tutuyor. Sessiz, aynı-girdi FCEUX
yakalama durumları 4661'de Start'ı, 4662–4691 arasındaki siyah paleti ve
4692'de başlık paletinin geri gelişini gösteriyor; FCEUX RGB tablosunda `$0F`
siyahtır. Bu, 30 siyah kare ve başlığın 4692'de görünmesi için kaynak kanıtı
sağlıyor. Godot'un aynı-girdi kare karşılaştırması ve ilk başlık pikselinin
alt-kare/dot zamanı açık; PPU/NMI/raster geçiş komutları henüz Godot'ta
yürütülmüyor.

`$A29B F8 00` artık bank-2 `$A4C0` hizmetini izleyen ROM-komut sunucusunda
yürütüyor: 15+16+48+42+4+51+240+60+15 bekleme adımı, 48 OAM-Y kaydırması,
başlık `$17` arka planının 16 satırlı temizliği ve 240 kayıt paketi, palet
kurulumu/solmaları, 51-adımlı `$44/$79/$7C` döngüsü, OAM temizliği, `$2000–$27FF`
PPU temizliği ve `$23C0–$23FF` `$55` yazımı eklendi. Sonraki `$DF` dispatch'i
kaynakta görülen 3968. kare kenarına bağlandı. `$17` paket hedefleri, sırası
ve NMI grupları iz ile eşleşiyor. Önceki tile farkının nedeni bulundu:
`$17` kaydının `$81` baytındaki bit 7, `$5B.0` seçicisini ve `$1100` blok
sayfasını belirliyor; `$8EF0` işaretçiyi `$A000 + 17*ID + $1100*selector`
olarak kuruyor. Seçili `$04` bloğu `$B144` / dosya `0x011154`; `$2084`,
`$20A4`, `$20C4` kuyruk örnekleri ve `$23C9=$AA` ile eşleşiyor. Extractor ve
iki Godot paket çözücüsü artık bu ROM sayfasını kullanıyor. Frame-4692 PPU
durumuyla 816 tile/attribute baytının 815'i eşleşiyor; kalan tek fark,
`$2208` satırındaki beklenen başlık imleci `$7F` yazımı. Sessiz, tam-açılış
izinde 48 blok çağrısının tamamı ROM kaydındaki satır-satır sırayla (31 farklı
ID), seçili sayfa işaretçileri, 768 ROM tile baytının CPU kuyruğuna kopyalanması
ve 48 attribute değerinin kuyruğa yazılması doğrulandı. `$05E8–$0627` kuyruk
yazılarından 240 paketin tamamı yeniden kuruldu; uzunluk, PPU hedefi, sıra ve
içerik ROM kaynaklı paket düzeniyle eşleşiyor (26×9 paket, ardından 6). Bu,
gözlenen F8 `$17/$80` yolu için canlı kaynak seçimi ve kuyruk paket üretimini
kapatıyor. `$8B52 ROL $5B` yazımı bit-7 seçicisini `$01` yapıyor.
`$9049/$903A` başlık düzeninin attribute adresini ve doğrudan bayt yazımını
doğruluyor; `$8FD8` birleştirme yolu bu sahnede çalışmıyor, `$064A` anlamı açık.
Tam CPU çevrimli PPU/NMI zamanlaması, raster bileşimi ve değişiklik sonrası
Godot karşılaştırması da açık. F8
ayrıntısı:
`reference/rom_extract/intro/f8_00_sequence_trace.md`.
Yükleme tamamlanınca 3597. karede `$44=$68`, preset 3 ve `$8E/$8F → $90/$91`
kopyası sıralandı; `7C 7E` değeri senkron RAM yakalama çapası, yazıcı yordamı
henüz bulunmadı. `$88FB` sonrası arka plan-arkası sprite kompoziti eklendi;
3600/3601 RAM karşılaştırmasında 64 OAM niteliğinin tamamı bit `$20` değiştiriyor.
Godot görüntüsü bu sayfa seçici düzeltmesinden sonra kaynakla karşılaştırılmadı.

İlk FE döngüsünün tekrar çapası `$A020 F2` için 379→4578 kare ölçümünden 4199
kare olarak kaydedildi; bilinen F1/EC/FD seçimleri bu döngü fazına
normalleştiriliyor. Açılışın kalan raster/OAM görünürlüğü, bazı EC/F1
bağlamları, `$17` payload farkı ve Start→başlık PPU geçişi nedeniyle hedef
tamamlanmış veya birebir doğrulanmış değil. Bu devam adımında Godot veya test
doğrulaması çalıştırılmadı.

**24 Ekim 2026 devam güncellemesi:** Ayrı ROM-byte komut sunucusuna çıkarılmış
F9/FA arka plan kayıtları için genel paket üretimi eklendi; ortak `$9B28` kuyruk
kapasitesi ve ROM blok/yerleşim doğrulamaları kullanılıyor. PPU renderer seçili
arka planın CHR banklarını ve ROM paletini değiştirebiliyor. İlk saha arka planı
için scanline 134 CHR değişimi yaklaşık satır sınırı olarak işleniyor; PPU
fetch gecikmesi hâlâ açık. F1 01 ve EE'nin kaynaklı 11×30 sıfırlamaları PPU
belleğine yazılıyor. F1 01'in dört `$BB9A` PPU kaydı ROM'dan ham çıkarılıp
hash doğrulamalı Godot loader'ına bağlandı; üç yakalanmış çağrı için doğrudan
ve NMI kuyruğuna alınan yollar uygulanıyor. EC 00 consumer'ı frame 380/385/390 gruplarını hazırlayıp
sonraki NMI'de yazıyor; 342→380 ilk beklemesi yakalama çapası. EC 05/02/04
akışları da `$BD4E/$BD24/$BD41` tabanlarından oynatılıyor; ilk gruplar 1120,
1780 ve 2369 karelerine yakalama çapasıyla bağlandı. EC 02'nin 1800–1839 arası
görev beklemesi gözlemden geldi, nedeni henüz ayrıştırılmadı. Title `$17` için
ayrı ROM paket çözücü ve 256×240 CHR/palet renderer eklendi; paket sırası,
çevre VRAM ve raster ayrıntıları varsayım. `$FE 20 A0` döngü komutu tanınıyor.
F3 00 yedi sonraki sahnede background kayıt baytı `$48` ile son FB animasyon
başlık baytından `$49` palet indekslerini seçiyor; raw `$D010/$D310` palet
kaynakları ve animation-header eşlemesi hash/byte doğrulamasına bağlandı. F4
04/05 yönleri ROM tablosu ve `$0631` telemetrisiyle eşleşiyor.
Title menüsü artık statik kare dokuları yerine ROM CHR, `$17` arka plan
kayıtları ve paletlerden endpoint görüntüsü oluşturan `RomTitleBackgroundRenderer`
kullanıyor; seçim imlecini kaynakta gözlenen bir karelik gecikmeyle `KICK OFF` /
`CONTINUE` arasında taşıyor, onaylamıyor. Yeni `title_rom_handoff_queue.gd`
Start-relative geçişte 240 paketi gözlenen 9'lu gruplarla sıraya koyuyor ve
bir sonraki modellenmiş karede PPU belleğine aktarıyor; palet/imleç 31. elapsed
karede commit edilince başlık açılıyor. Grup ve frame sınırları capture-anchored; 4662–4692 aynı-girdi Godot yakalaması RGB'de %100 eşleşiyor, CPU/NMI alt-kare fazı açık.
Bu nottaki ana-sahne bağlantı durumu daha sonraki entegrasyonla değişti:
`scenes/main.tscn`, `opening_source_runtime.gd` üzerinden ROM komut sunucusunu,
ROM türevi ses çıktısını ve ROM paketlerinden kurulan başlık menüsünü çalıştırıyor.
Komut yorumlayıcısının tüm NES kodunu/yardımcılarını kapsaması ve açılışın tüm
sahnelerinde tam kare/piksel/ses eşleşmesi hâlâ tamamlanmadı.

Son devam adımında kaynak-komut prototipi F9 01'in ötesine taşındı. ROM'dan çıkarılan 64 metatile blok ve alan kaydı, attr-önce/satır-satır sırasıyla 320 `$05E8` paketi (1.088 PPU yazımı) üretiyor; `$9B28` kapasite davranışı gözlenen frame 344–379 NMI gruplarına adres ve bayt bazında uyuyor. F9 işaretçisi frame 378'de ilerliyor, son beş paket frame 379 NMI'sinde aktarılıyor. 256×240 ROM-CHR nametable çizicisi bu belleği kullanıyor. `$F3 00` frame 378'de kalan `$0628=$20` kuyruk alanında 32 bayt palet rezervasyonu yapamayınca `$9B2E` üzerinden bir release bekliyor; frame 379'da background palette 02 ve animasyon palet indeksi 00'dan gelen ROM paletini kurup sonraki NMI için hazırlıyor. Bu palette kaynakları korunmuş ROM baytlarıdır; frame 380 PPU paletiyle byte-match ediyor. Aynı frame 379'da ilk `$4B` glyph'i `$82 49 22 00 4B` PPU paketine giriyor; frame 380 NMI'sinde `$2249/$2269` adreslerine gidiyor. `$F2 05` için glyph başına beş scheduler release ve ilk metin satırındaki adres ilerlemesi modellendi; FC sonrasındaki metin imleci/nametable adresi henüz çözümlü değil. `$F4 04/05` dört palette değeri için dörter release'lik geçişler olarak eklendi. `6E` runner animasyonu ve RAM yakalamalarında görülen Q8.8 x-özyinelemesi kaynak-frame saatiyle yürütülüyor; F7 normal handler’ının operandları +0C..+0E alanlarına taşıdığı ROM baytlarından çözüldü; canlı $94/$95 hedef pointer’ı ve sonraki per-frame integrator henüz izlenmedi. Bu satır eski prototip durumunu kaydeder; sonraki geliştirmede EC consumer, sonraki arka plan/metin/OAM yolu, ROM-driver audio asset ve başlık geçişi ana sahneye bağlandı. Bu yüzden açılış tamamlandı veya birebir doğrulandı denmiyor. Başlık imleci görünür güncellemesi Down frame 4693 → 4694 olarak izleniyor; aktif ana sahne PPU kuyruğunu ROM-byte sunucusuyla yürütüyor; çözülmemiş kısım tüm komut yardımcıları ve kare-içi NMI/IRQ raster fazıdır.

Eski soğuk-açılış manifestindeki hatalı 26 karelik siyah bekleme düzeltmesi tarihsel not olarak korunuyor: o yaklaşım 13–25 için ROM CHR/PPU/RAM'den üretilmiş kareleri kullanıyordu. Aktif `scenes/main.tscn` artık bu manifesti yürütmüyor; `opening_source_runtime.gd` içindeki `ColdStartSourceCommandPresenter` kaynak komut baytlarını ve scheduler modelini çalıştırıyor. Tam raster/piksel zamanlaması yine de tüm sahnelerde kanıtlanmadı.

Start sonrası FCEUX PCM kuyruğu frame 4679'a dek sürüyor. ROM stop'u tüm APU girişini sıfırlamıyor: `$4015=$0F` DMC fetch'lerini durdururken pulse, triangle ve noise'u etkin bırakıyor; `$4000/$4004/$400C=$30` pulse/noise ses düzeyini sıfırlıyor, `$4008=$30` ise triangle linear-counter kontrol bitini temizliyor ama triangle DAC'ını sıfırlamıyor. Son nota `$400B=$19` ve uzunluk sayacı 2 ile frame 4650'de yükleniyor; stop sonrası yaklaşık 0,84 kare içinde sayaç bittiğinde iz ve FCEUX kaynak koduyla yürütülen model triangle DAC adım 21'de (seviye 15) tutulacağını öngörüyor; ham iz `tristep` değerini doğrudan kaydetmiyor. DMC `$4011` DAC latch'i `$60` olarak kalıyor; `$4015` bunu temizlemiyor. Ardından WaveHi TND girdisi sabit triangle 15 + DMC 96 = 111 oluyor; FCEUX tail'i hem bu kaynak düzeyi hem de 1024-tap FIR/`SexyFilter` hafızasından geliyor. Profil kaynakta sabitlendi (NTSC, `soundq=2`, 44.1 kHz, master/kanal gain 256, low-pass kapalı); kalan fark filter config değil, tam kaynak-cycle triangle/DMC fazı ve bu akıştan oluşan FIR/filtre state'i. ChannelBC adayı stop kuyruğunda korelasyon 0.99426 olsa da RMS yaklaşık %18 yüksek ve timing event'lerini FCEUX izinden alıyor; runtime WAV değişmedi. Byte/trace ayrıntısı `reference/rom_extract/audio/post_stop_filter_tail_source_trace_20261025.md` içinde. `$0700` kuyruğundaki `$01`, `$8BDA` ses tablosunun `$8E42` stop-all akışını seçiyor; önceki yaklaşık 20 karelik geç stop farkı ROM komutu değil NSF açılış fazıydı.

Kaynaklı NSF/FCEUX çevrimdışı renderının ilk cue farkı +3 kareden 0'a indi (260–330 aralığında korelasyon 0.9985). Sonraki cue'larda tercih edilen fark -6 ile +6 arasında değişiyor; 260–4660 geniş aralığında en iyi korelasyon 0.523. Precise, aynı-girdili FCEUX kaydının 3.442.925 örnek uzunluğu 139.730.109 CPU çevrimi ve `soundq=2` FIR başlangıç fazıyla açıklanıyor; kaynak frame 0 satırı sıfır çevrim içerdiğinden PCM hizası satır sayısından değil çevrim/örnek sınırından yapılmalı (`reference/diagnostics/audio/precise_pcm_sample_alignment_20261024.json`). Ayrı 4700 frameadvance NSF probundaki 3.461.217 örnek hâlâ açıklanmadı ve tail hizasında kullanılmamalı. Doğru sınır hesabına rağmen yalnız son SexyFilter yinelemesini libgme çıktısına uygulamak kuyruk sesini eşleştirmiyor; upstream mixer/resampler durumu da gerekiyor. Runtime WAV değişmedi; yakalanmış WAV yalnız karşılaştırma, tahmini fade yok. Ölçümler `reference/diagnostics/audio/start_tail_audit_20261024.json` ve hassas örnek hesabı JSON'unda; ROM-sürücü tabanlı çevrimdışı ses üretimi için sonraki adım `reference/rom_extract/audio/offline_renderer_next_step.md` içindedir.

ROM kaynaklı başlık karesi ve çalışan `KICK OFF` / `CONTINUE` imleci Godot ana sahnesine bağlıdır. Kare 4692 için önceki 61.440/61.440 RGB piksel eşleşmesi, `$17` header bit-7 blok sayfası Godot'a aktarılmadan önce ölçüldü; bunu güncel runtime doğrulaması sayma. Yeni statik PPU byte karşılaştırması seçili ROM blok sayfasıyla 815/816 payload baytını eşleştiriyor; tek fark beklenen `$7F` cursor overlay'i. Bu tarihli nottan sonra 4662–4692 başlık-geçiş kareleri Godot'ta doğrudan yakalanıp FCEUX ile %100 RGB eşleştirildi. Tam açılışın 929 değişen karesi daha önce Godot'ta oynatıldı; soğuk açılış logosu bir kez görünür, intro 282. kareye döner ve Start kısa geçişle başlığa götürür. Ses, ROM sürücüsünden çevrimdışı üretildi; 12 açılış `ED` komutunun tamamı canlı CPU/MMC3 izi ve ROM baytlarıyla doğrulandı: `$58`, `$68`, `$28`, `$0E`, `$02`, `$09`, `$07` cue'ları ve 282–4578 karelerindeki tekrarları. `$FC` bank-0 `$8837` yoluna dispatch edilir ve script pointer'ını tek bayt ilerletir; eski counted-payload yorumu ve ona dayalı olay sınırları geçersizdir. Provenance düzeltmesinden sonra WAV yeniden üretildi; PCM SHA-256 değişmedi. APU stop sonrası PCM kuyruğu hâlâ eşleşmiyor.


Saha-koşucusu CHR düzeninin bir parçası artık kaynak kodu ve aynı-kare bus iziyle ayrıştırıldı: bank-2 `$A1CB` rutini Y=`$16` iken RAM `$8E/$8F` değerleri `$3C/$3E` ile üst çift bankı, Y=`$18` iken `$90/$91` değerleri `$00/$02` ile ikinci çifti `$8000/$8001` üzerinden seçiyor. Kare 380–808'in 429 karesinin tamamında bu RAM çiftleri sabit; `$3C/$3E` vblank'te geri yükleniyor, `$00/$02` ise her kare scanline 134, dot 131–213 aralığında yazılıyor. Bu, 134. satırın tamamına uygulanmış tek bir PPU bandını kanıtlamaz: yazmalar görünür satırın ortasında tamamlanıyor ve ilk yeni bank pikseli 2C02 pattern fetch/shifter gecikmesi çözülmeden bilinmiyor. Ayrıntı ve ROM baytları `reference/rom_extract/intro/field_runner_chr_raster_split_trace.md` içindedir; bu yüzden çözülmemiş latch/pipeline farkı açık kalıyor.

**Reverse engineering düzeyi:** Aktif ana sahne `cutscene_00.bin` baytlarını `ColdStartSourceCommandPresenter` ve `RomCooperativeScheduler` üzerinden yürütüyor; ROM-türevli background, palette, animation, text ve PPU queue kaynaklarını kullanıyor. Bu tam 6502/PPU/APU emülatörü değildir: bazı komut/helper etkileri kapsam dışı, bazı kare/NMI fazları yakalama dayanaklıdır ve ses şu anda ROM-driver'dan çevrimdışı üretilmiş WAV olarak çalınır. Yeni sessiz FCEUX izinde 585 interpreter dispatch'i kaydedildi: ilk geçişte `$A020`'den `$A29E`'deki `$FE` komutuna kadar 551 dispatch var; `$FE` bank-0 `$8862` handler'ı hedef `$A020`'yi pointer'a yazar ve yorumlayıcıyı yeniden başlatarak açılışı koşulsuz döngüye sokar. Bu tek bir açılış oynatımının ardından gelen otomatik script döngüsüdür; Continue/Kickoff onayı değildir. Aynı replay ikinci geçişte `$A020–$A050`'ye ulaştı. Start 4661. kaynak karesinde basılı kaldı (4661–4667); script pointer'ı kare 4662 sonuna kadar `$A050`'de kaldı, kare 4663 içindeki yürütme `$A0E5`'ten `$00E5`'e geçti ve `$00E7`'ye ilerledi, kare 4664'te `$00E8` oldu. Bu, başlık geçişi için gözlenen pointer handoff penceresidir; tam raster görünürlük/PPU commit kenarı ayrı doğrulanmalıdır. FC handler'ı için doğrulanan yol bank-0 tablo sözcüğü `$8836` → RTS sonrası `$8837`; örnek `$A054` dispatch'inden sonraki pointer `$A055`'tir. Dolayısıyla FC izlenen bağlamda sonraki byte'ı payload saymıyor. Önceki 62-event `$A020–$A6DB` parse ve `$A326` EB kaydı FC-count varsayımıyla üretildiğinden yürütme kanıtı olarak geri çekildi; korunmuş ama withdrawn işaretli VM JSON'u kullanma. İz metni `<D8`, `$D8–$DF` bekleme, `$E0–$E7` cursor geri alma ve `$E8–$FF` vektör dispatch sınıflarını kaydediyor; her vektör hedefi ve post-handler pointer ölçüldü. Yeni kaynak tablosu ilk geçişte erişilen 18 vektörün operand uzunluğunu ve kanıtlı RAM/PPU/APU etkilerini ayırıyor. Araştırma stepperı F2 yazı hızı, ED ses kuyruğu, FC tek baytlı state değişimi ve FE döngüsü gibi doğrulanmış etkileri kaydediyor; çözülmemiş helper sonuçlarını ve PPU görünürlük zamanlamasını uygulamıyor. Ayrıntı `reference/rom_extract/intro/cold_start_vector_handler_semantics.md` içindedir. Doğrulanmış sıra `reference/rom_extract/intro/cold_start_observed_dispatch.json`, ham iz `reference/diagnostics/opening_dispatch_full_20261024_150016/opcode_flow.csv`, geçiş PC izi `reference/diagnostics/title_transition_pc_20261024_150231/pc_trace.csv` içindedir. Kare 837–845'te görülen PPU register yazmaları bağımsız bus kanıtıdır: `$2000=$84` nedeniyle `$2007` yazmaları adresi her seferinde 32 artırır; bunları FC payload'ına bağlayan eski sonuç geri çekildi. Açılışın kalan PPU görünür kenarları ve raster çizim mantığı çözülmelidir. Sonraki adım kalan vektör yardımcılarının kaynak etkilerini ve NMI/PPU commit zamanlamasını çözmek, sonra aynı girdi karşılaştırmalarında kalan sahne/OAM/scanline farklarını kapatmaktır.

İnternet araştırması açılış için önemli kaynaklar buldu: çevrimiçi CT2 6502 disassembly'sinin bank-80, bank-81, bank-87 ve bank-FF listelerindeki sırasıyla 3.872, 2.118, 3.869 ve 4.797 anotasyonlu bayt kaydı sağlanan Türk ROM ile eşleşti. Bu, her banka veya yorumun eşleştiği anlamına gelmez; bank-82, bank-98 ve bank-A7'de uyuşmayan kayıtlar bulundu. Eşleşen bank-80 notları açılış girişini `$801F/$8022`, Start döngüsünü `$8027–$8032`, ses durdurmayı `$8048`, başlık kurulumunu `$807A`, başlık giriş beklemesini `$80A2` ve KICK OFF dalını `$80E1/$80E6` olarak işaretli; bank-87 sahne tablosu açılış ve başlık arka plan ID'lerini listeliyor. Japonca adres notu `0x6010` OP demo başlangıcını doğrulayan ipucu; `0x62B1`'deki “Start sonrası demo” akışının bu açılışın Start→başlık yolunda yürütüldüğü ise kanıtlanmadı. Türkçe müzik tablosundaki Sound 00 işaretçisi `0x18C98 → 0x1F7BD` yerel ROM'da eşleşiyor; ayrıca ses sürücüsünün ID-1 pointer hesabı canlı `$ED $58` kuyruğunu aynı girişe çözüyor. Yani runtime `$58`, Sound 00'a eşleniyor; bu, Sound Test numarası `$58` olduğu anlamına gelmiyor. Çin Hack CT2 editörü CHR/müzik/RAM düzenleme aracı; tam 6502 çözümlemesi değildir. Ayrıntılı karşılaştırma ve sınırlar `reference/rom_extract/intro/online_reverse_engineering_resources.md` ve `reference/rom_extract/intro/ed58_music_mapping.md` içinde.

İlk kaynak-komutlu soğuk açılış sunucusu ayrı prototip sahnesine eklendi. `E8 01`, `F9 00`, `FB 01 8D`, `E9`, `DF`, `EA`, `ED 58` dispatch'lerini gözlenen sıra/karelerde işler ve her tüketilen script baytını `cutscene_00.bin` ile çalışma anında eşleştirir; ROM-derived arka plan ve sprite çizicilerini kullanır. EA için ROM `$99F0/$9A71/$9AA2/$9EA2` rutinlerinden çözülen palet dönüştürme, bir-NMI gecikmeli packet commit'i ve kare 282 sıfır temizleme son durumu izole sunucuya eklendi. Üretilen 32 baytlık palette packet'ları senkronize RAM yakalamalarında kare 267–281 için eşleşti. Sessiz, aynı girişli FCEUX ekran yakalaması ve PPU/RAM snapshot eşleşmesi, logo görünürlüğünü kaynak frame 13'ün çıktı satırı 77'sine (ilk logo pikseli x=79) ve tam siyah ekranı source frame 282'nin ilk görünür scanline'ına yerleştiriyor. PPU dot düzeyindeki ilk/son piksel kenarı ve ara karelerin tam raster bileşimi hâlâ ölçülmedi. Kare zamanları hâlâ gözlenen replay sınırlarına dayanıyor; E9/EA'nın tam kaynak-zamanlı PPU yürütümü, ses bağlantısı ve frame 282 sonrası komutlar eksik. Prototip ana sahneye bağlanmadı. Ayrıntı `reference/rom_extract/intro/cold_start_visible_edge_audit.md`, `docs/cold-start-source-command-presenter.md` ve `reference/rom_extract/intro/ea_fade/README.md` içinde; aktif ana sahne hâlâ zaman çizelgesi sunucusunu kullanıyor.

E9 solmasının ROM davranışı `$8580` → `$9FA8(A=$02)` iki NMI bırakımı → `$997E` sayaç/LUT adımları → `$9A71/$9AA2/$9EA2` 32 renkli packet üretimi olarak çözüldü; NMI bir önceki packet'ı PPU'ya yüklüyor. Tarihsel ilk uygulama adımı: E8/F9/FB/E9/DF/EA/ED komut aralığı ayrı `scenes/prototypes/cold_start_source_command_presenter.tscn` sunucusunda, `cutscene_00.bin` baytlarını hash-check ederek ve `scripts/opening/rom_cooperative_scheduler.gd` üzerinden çalıştırılıyor; `$ED $58`'de Sound 00 isteğini yayıp duruyor. ROM `$0005` task slotuna `$FF` hazır işareti yazar; ilk scheduler dispatch’inin source frame 8’de görünmesi yakalama zaman hizasıdır, ROM’da 8-tick bekleme yok. F9 background-00 yolundaki iki ayrı `$9FA8(A=$01)` bırakımı `$8BB0` loader beklemesi ve `$0628=$39`/`$0629=$04` rezervasyonunun `$9B2E` kapasite beklemesi olarak çözüldü; F9 pointer'ı `$A022`'de ikinci resume'e kadar kalıyor, frame 10'da F9 ilerleyip FB dispatch ediliyor. Kare içindeki NMI/yield fazı bilinmiyor. Bu paragraf erken prototipin izole durumunu kaydeder. Güncel ana sahne ROM komut sunucusunu çalıştırıyor; diğer sahnelerin tam PPU/raster zamanlaması ve APU kuyruk sesi hâlâ açık. Önizleme/karşılaştırma olmadan birebirlik iddiası yok. Ayrıntı `reference/rom_extract/intro/e9_fade_up_trace.md`, `reference/rom_extract/intro/f9_task_timing_trace.md` ve `docs/cold-start-source-command-presenter.md` içinde.

ROM görev taramasının modeli `scripts/opening/rom_cooperative_scheduler.gd` içine eklendi ve ilk ROM-byte sunucusuna bağlandı: altı task-slot sırası, NMI-ready bitini tek kez tüketme, sayaç düşürme, sıfıra inen tek görevi uyandırma ve `$9FA8(A=n)` yield davranışı. `$8464→$9F69` worker kurulumunda `$0005=$FF` yazıldığı ve bunun hazır task olduğu, ilk dispatch’in capture’da frame 8’de ölçüldüğü doğrulandı; `$0055=$08` ise metin hızıdır. Prototipin ilk scheduler release’i hâlâ frame 8’e yakalama-hizalıdır, bu gerçek reset/startup NMI fazını yeniden üretmez. Task stack/mapper geri yükleme, cycle düzeyi NMI/PPU raster ve kalan VM komutları kapsam dışında. Ayrıntı `reference/rom_extract/intro/cutscene_boot_task_install_trace.md` ve `reference/rom_extract/intro/cold_start_scheduler_tick_trace.md` içinde.

Çin/Japon/Türkçe kaynak araştırması byte-matched disassembly ve Japonca adres notlarının yanı sıra açılışa özel teknik izler sağlıyor. Japonca not `0x6010`'da OP demo, `0x62B1`'de Start sonrası demo, `0x6636`'da Carlos maçı adreslerini listeliyor; yerel Türk ROM'u ve çalıştırma izi açılış adresini doğruluyor, ancak `0x62B1`'in bu Start→başlık yolunda yürütüldüğü kanıtlanmadı. EA palette fade için kaynak kodundan `$99F0/$9A71/$9AA2/$9EA2` davranışı ve dört verbatim ROM kod/tablo kesiti çözüldü; kaynak renklerin kare 267–281 RAM packet'larına dönüşümü bayt bayt eşleşti. Yeni sessiz kare yakalaması source frame 281'de logo çıktısını, frame 282'de ise tamamen siyah çıktıyı gösterdi; synchronized PPU izinde frame 282'nin palette yüklemesi vblank'te, görünür scanline 0'dan önce gerçekleşiyor. `$858D` EA handler'ının clear helper çağrıları ve 1.536 sıfır yazımı ROM baytları/PC-tagged bus kaydıyla eşleşti. İlk logo pikseli output `(79,77)` olarak ölçüldü; PPU dot koordinatı ve scanline içindeki son piksel kenarı hâlâ doğrudan yakalanmadı. Ayrıntı ve capture sınırlamaları `reference/rom_extract/intro/cold_start_visible_edge_audit.md` içinde.

Araştırma notu Japonca/Türkçe çevrimiçi adresleri ROM'a göre genişletti: eşleşen disassembly bank-87'nin `0xE010` sahne tablosu anotasyonları 3.869/3.869 baytta yerel ROM'la eşleşiyor ve açılış/title background ID'lerini adlandırıyor. Canlı ses sürücüsü izi `$ED $58 → $8BDA` tablo seçimi → file `0x18C98` → bank `$0F` adresi `$B7AD` → file `0x1F7BD` yolunu doğruluyor; bu parça Sound 00'dır. Runtime cue sayısı ile Sound Test ordinal'i ayrı tutuluyor. Japonca gameplay/analiz sayfaları mekanik referansıdır; Çin Hack CT2 ve CT2-Editor-Advance araç/katalog sağlar, tam 6502 kod çözümü değildir. Ayrıntı ve sınırlar `reference/rom_extract/intro/online_reverse_engineering_resources.md`, `reference/rom_extract/intro/ed58_music_mapping.md` ve `reference/rom_extract/intro/regional_sources_followup.md` içindedir.

Tarihsel prototip notu: ilk altı Tecmo Theatre komutunu çalıştıran yalıtılmış sunucu `scenes/prototypes/cold_start_logo_presenter.tscn` içinde eklendi; sonraki komut sunucusu ayrı sahne olarak genişletilip aktif ana sahneye bağlandı. Bu sahne ROM'dan çözülen CHR/palet kaynakları, sprite animasyonu `0x8D` ve 240-tick beklemeyi birleştirir; ROM'u yüklemez ve ana açılış sahnesine henüz bağlı değildir. Sprite paleti kaynağı ROM file `0x00D670` olarak izlenmiştir ve PPU palette RAM'iyle eşleşir. Arka planın “TECMO THEATER” harfleri için frame-26 PPU nametable tile kimlikleri ve frame 10–11 PPU yazı aralıkları belgelenerek çizici düzeltildi. İlk birleşik önizlemede karakterin görünmemesinin nedeni Godot JSON sayılarının `141.0` float olarak gelmesi ve `Array.has(141)` kontrolünün başarısız olmasıydı; ID tam sayıya dönüştürüldü. Frame-26 RAM OAM gölgesi, ROM `$B15B` descriptor'larıyla başlangıç `(80,96)` konumunda 40/40 bayt eşleşiyor; yakalanmış dört sprite CHR sayfası da ROM `7C 71 52 53` bankalarıyla eşleşiyor. İki karelik Godot önizlemesinde karakter ve logo birlikte görünüyor. `E8 01` preset izi artık `$BF13` / ROM `0x00DF23` kaynağını ve 19 ROM baytının `$79`, `$7C–$8D` alanlarına kopyalanmasını doğruluyor; `$7A` sıfırlanıyor ve `$7B` kopya tarafından değiştirilmeden kalıyor. `$79` MMC3 IRQ/raster kurulumunda kullanılıyor; kalan preset baytlarının tüketicileri ve görünürlük/PPU commit karesi hâlâ çözülmedi. Bu ilk yalıtılmış prototip aktif runtime değildi; güncel ana runtime komut sunucusunu kullanıyor. Bu eski iki-kare önizlemesi tek başına açılışın birebir olduğunu kanıtlamaz.

ROM yorumlayıcı prototipi artık F2 yazı temposunda her özgün tile ID'yi ayrı ayrı ilerletiyor; hız 1 ve 5 için gözlenen 1/5 karelik glif aralığı ROM kodu ve RAM/PPU kayıtlarıyla belgeli. Eski FC-count handler ve entry-0 sınırı bulguları canlı replay ile çeliştiği için geri çekildi. FC komutu için doğrulanan örnek dispatch PC'si `$8837` (MMC3 R6=`$00`, R7=`$03`); handler `$99` bayraklarını güncelliyor, `$9FA8` yardımcısını çağırıyor ve `$51:$52` değerini `$40` artırıyor; sonraki script dispatch pointer'ı `$A055`. Bu doğrudan etkiler `cold_start_vector_handler_semantics.md` ve araştırma stepper'ında kayıtlı. Yeni `reference/rom_extract/intro/cold_start_palette_nmi_commit_trace.md` izi, F3/F4'ün `$05E8` kuyruğuna yazdığı 32 renkli paketin `$C76E → $C421 → bank-2:$A000` NMI yolunda `$2006/$2007` ile yüklendiğini doğruluyor; örnek palette geçişlerinde kare sonundaki RAM paketi sonraki NMI'da yazılıyor ve PPU paletiyle bayt bayt eşleşiyor. Yeni [`cold_start_scheduler_tick_trace.md`](rom_extract/intro/cold_start_scheduler_tick_trace.md) izi, gözlenen açılışta `$C76E` bit-6 yolunun `$C421 → bank-2:$A000` üzerinden `$1B.7` hazır bitini `$A133`’te yazdığını (normal NMI yolu aynı biti `$C7EE`’de yazar), `$9EED`’in bu tek-bit işaretini tüketip görev sayaçlarını kaynak slot sırasıyla azalttığını; sayaç sıfıra inince görevi hemen bağlam değiştirerek tek tek yürüttüğünü gösteriyor. `$9FA8(A=n)` her çağrıyı bir tik saymaz; görev gecikmesini kaydedip bırakır ve her NMI hazır işaretinde scheduler tekrar ilerler. `$DF`, `$8AE6` tablosundaki `$F0` = 240 tik değerini kullanır: aynı girişli izde pointer `$A028` frame 27’den `$A029` frame 267’ye geçti; 240 kare/NMI aralığı RAM sayaç düşüşleriyle tutarlı. FCEUX çevrim farklarının ortalaması 29.780,5006 CPU cycle/frame, yani NTSC 1.789.773 Hz CPU saatiyle 60,09882 kare/s verir. `$899A` bekleme değildir, yalnız `$99` bayraklarını ayarlar; eski scheduler yakalama CSV’sindeki hook adı bu anlamda yanıltıcıdır. Bu iz gözlenen `$DF` gecikmesini kaynak-tanımlı hale getiriyor; diğer komutların tüm görünür süreleri ve raster/piksel kenarları hâlâ tamamlanmadı. Synchronized trace palette writes'ları vblank scanline 246–251'e yerleştiriyor; tam ilk renkli piksel doğrulanmadı. `$A1B0` ve `$A2A1` hakkındaki eski payload alias sonuçları geçersizdir. İlk saha-koşucusu bölümü için `0x6E` sprite descriptor/zaman verileri ve ROM handler'ında F8 `0A` komutunun `$000D/$000E` durum baytlarını sıfırladığı çözüldü; bu komut karelik hareketi yapmıyor. Yeni `runner_motion_live_bridge.md` izi, F7 store anında `$94/$95=$0568` olduğunu ve `$975B`'nin her tikte signed acceleration'ı hıza ekleyip yeni hızı konuma taşıdığını ROM baytları ve canlı PC/RAM yazımlarıyla doğruladı. `rom_runner_motion_record.gd` artık ROM F1/F7 bytecode'u ve animasyon timing kaydını kullanarak `$0568` nesnesini ve `$975B` hareket sırasını Godot'ta yürütüyor; aynı-girdi RAM/OAM shadow, ekran konumu ve raster karşılaştırması henüz yapılmadı. Ana sahne ROM yorumlayıcısına bütünüyle bağlanmadı; renkli görünürlük ve raster bileşimi kare/piksel düzeyinde hâlâ tam doğrulanmadı.


Yalıtılmış Tecmo Theatre sunucusunun doğrudan Godot karesi frame-26 PPU referansıyla 61.031/61.440 pikselde eşleşti. Kalan 409 pikselin tümü harf alanındaydı; kare-26 üst raster bandındaki `$FF` dikey scroll uygulanınca, arka plan bir piksel aşağı çizildi ve sprite sabit bırakılarak doğrudan viewport karesine uygulanan katmanlı dönüşüm referansla 61.440/61.440 RGB pikselde eşleşti. Renderer'a aynı arka plan ofseti eklendi. Tile kimlikleri PPU nametable'dan, desenleri üst bandın fiziksel CHR bankı 124'ten doğrulandı; kare sonundaki bank 0–3 görünümünün bu alan için kullanılması hatalı olurdu. Bu tarihli not runtime doğrudan yakalamasından önce yazıldı; sonraki 275-kare tekrarlanan-logo penceresi aynı-input Godot/FCEUX karşılaştırmasında %100 eşleşti. Logo palette packet'ının `$05E8` staging alanından NMI içindeki `$A000` tüketicisine giden yolu ve frame-13 yüklemesi kaynak kodu/bus iziyle çözüldü; scanline 0 yalnızca ilk renkli çıktı için en erken makul kenardır, doğrulanmış piksel/scanline değildir. Ayrıntı `reference/rom_extract/intro/logo_frame26_glyph_trace.md`, `reference/rom_extract/intro/cold_start_palette_nmi_commit_trace.md` ve `docs/cold-start-logo-presenter.md` içindedir.

Soğuk başlangıç izi eski “0–25 siyah, logo 26'da başlar” varsayımını düzeltti: `$2001=$1E` render etkinlemesi ve logo tile verisi daha önce geliyor; frame12 oyun alanı siyah, source frame13 ekran çıktısı ilk logo pikselini `(79,77)`'de gösteriyor. Synchronized trace'te palette paketi source frame13 görünür satırlarından önce, PPU scanline 246–251'de yükleniyor; screenshot/PPU-RAM eşlemesi ilk görünür logo satırını 77'ye daraltıyor, fakat pixel-dot hook yok. Kare 26 iyi belgelenmiş daha sonraki kompozisyon karesidir. Script pointer'ı `$A027` E9 beklerken frame 10, `$A028` DF beklerken frame 27, `$A029` EA beklerken frame 267, `$A02C` sound cue sonrası frame 282'dir. EA sırasında palet 268–281'de aşamalı değişir; frame281'de logo hâlâ görünür, frame282 çıktısı tamamen siyahtır. Son 32-byte `$0F` palette aktarımı vblank'te, görünür scanline 0'dan önce; mask kapalı temizlik frame282 scanline55–196 arasında tamamlanıyor. ROM EA clear rutini `$2000`'de 16×32 ve `$2400`'de 32×32 sıfır yazar (PC `$9953`'ten 1.536 `$2007` yazımı); tam siyah görüntünün ilk görünür sınırı source frame282 scanline0 olarak destekleniyor, dot kenarı doğrudan örneklenmedi. Bu erken izole sunucu `begin()` çağrısını hemen yapıp soyut VM tick'lerini NES karelerine eşitliyordu; aktif ana sahneye bağlanmadığı eski durum sonradan değişti. Güncel source presenter ROM script/scheduler'ını yürütür, fakat frame-8 ilk release hâlâ capture anchor'dır ve tam reset-to-NMI alt-kare fazı çözülmemiştir. Proven/gap ayrımı `reference/rom_extract/intro/cold_start_visible_edge_audit.md`, `reference/rom_extract/intro/cold_start_ppu_timing_trace.md` ve `reference/rom_extract/intro/cold_start_palette_nmi_commit_trace.md` içindedir.

Başlık geçişi için ROM kodu ve sessiz, aynı-girdi FCEUX izi ayrıca eşleştirildi. Start yeni-basım kenarı frame 4661'de bank-0 `$8027–$8032` döngüsünden çıkar ve `$8048` `$0700` ses kuyruğuna stop ID `$01` yazar; stop APU'yu tamamen sessize almaz: DMC fetch'i durur, pulse/noise volume sıfırlanır, triangle DAC ile DMC DAC latch'i tutulur ve filtre kuyruğu frame 4679'a dek sürer (ayrıntı yukarıdaki ses izinde). Aynı replay'de komut işaretçisi frame 4663'te `$A0E5→$00E5→$00E7`, frame 4664'te `$00E8` olur. Başlık arka plan yüklemesi `$806A→$8AF7(A=$17)` ile frame 4664'te başlar; kuyrukta tüm 240 ROM kaynaklı paket 26×9 ve son 6 olarak 4690'a kadar işlenir, ardından `$806F` yardımcı zinciri çalışır. Frame 4691'de `$3F00` palet paketi ve `$220A` adresine `$7F` imleç paketi kuyruğa yazılır; ikisi de frame-4692 PPU yakalamasıyla eşleşir. `$220A=$7F`, `$224A=0` olduğundan ilk seçim `KICK OFF`'tır. Ayrı Down-only denemesinde giriş kenarı frame 4693, görünür `$7F` taşıması `$220A→$224A` frame 4694'tür. Bu iz kaynak paket üretimi ve gözlenen kare sınırlarını doğrular; 4662–4692 Godot/FCEUX RGB karşılaştırması %100'dür, ancak ilk görünür scanline/dot ve tam PPU raster fazı hâlâ ölçülmemiştir. Kaynak adresleri, ROM byte kontrolü ve kalan boşluklar `reference/rom_extract/intro/title_menu_source_trace.md` içindedir.

Başlık yardımcıları için ROM byte'ları ile senkronize sessiz FCEUX bus/RAM/PPU kaydı eşlendi. `$890C`, 64 OAM kaydının Y koordinatına `$30` ekliyor; `$88FB` özniteliklerde sprite-öncelik biti `$20`'yi XOR'layıp başlık OAM düzenini ROM descriptor'larıyla eşleştiriyor. `$9A35` ROM'dan gelen 32 renk palet paketini `$05E8` kuyruğuna hazırlıyor; frame 4691'de RAM'deki paket frame 4692 NMI'sinde `$3F00` PPU adresine yazılıyor ve PPU paleti bayt bayt eşleşiyor. `$8920` başlıkta A=`$00` ile bank-6 `$BF10` kaydındaki 19 sıfır baytı yükleyerek `$79` ve `$7B–$8C` durumunu temizliyor. `$98E8/$98EA` PPU satır yazılarını kuyruklayıp NMI tüketicisine bırakıyor: `$7F` frame 4691'de `$220A` için hazırlanıp frame 4692'de yazılıyor; Down hareketinin yeni imleci frame 4694'te görünür. `$8AF7` ID `$17` kaydının kaynak CHR banklarını, `$D020` paletini ve 6×8 metatile alanını doğruladık; ancak kaydın bütün alanlarını kuyruk paketlerine bağlayan parser/haritalama tamamlanmadı. Godot başlık geçişi artık `$17` paketlerini kaynak sırasıyla, canlı izdeki dokuzlu gruplarda sıraya koyup bir sonraki modellenmiş karede PPU belleğine aktarıyor; ROM paleti ve `$7F` imleç frame 31 commitinden sonra gösteriliyor. Bu runner capture-anchored batch/frame schedule kullanıyor; Start poll, `$8AF7`/`$9A35`/`$98E8/$98EA` CPU yürütmesi ve gerçek NMI alt-kare döngüsü hâlâ modellenmiyor. Same-input Godot karşılaştırması ve ilk görünür piksel/raster doğrulaması açık. Ayrıntılı kaynak izi ve açıklar `reference/rom_extract/intro/title_menu_source_trace.md` içinde.

Yeni bölgesel kaynak kontrolü: TsubasaTR'nin [Karşılama Açılış Ekranı Hakkında Bilgiler](https://www.tsubasatr.net/portal.php?page=414) yazısındaki `0xD020` palet adresi ve 16 baytlık dizi (`0F 16 00 30 0F 0F 0F 0F 0F 11 00 30 0F 0F 16 26`) sağlanan ROM'da birebir eşleşiyor; frame 26'nın yakalanmış PPU `0x3F00` paleti de aynı. Bu adres/dizi doğrulandı, tek tek renk adlandırmaları forum yorumudur ve tile/attribute eşlemesi ayrıca doğrulanmalıdır. Aynı forumun genel ara-sahne örnek komutları bu ROM'un soğuk açılış baytlarıyla eşleşmiyor; örneğin canlı `DC` komutunun ROM tablosundaki değeri 60 scheduler-frame, forumdaki 1.6 saniye açıklaması bu akışta birebir süre olarak kullanılmamalıdır. Kaynaklar, byte karşılaştırmaları ve kısıtlar `reference/rom_extract/intro/online_reverse_engineering_resources.md` içinde.

Çin kaynaklarında tam 6502 disassembly veya “oyunun tüm kodları çözüldü” iddiasını doğrulayan bir çalışma bulunmadı. Hack CT2 ROM editörü/inceleme aracıdır; ilişkili CT2-Editor-Advance deposunda ise kesit animasyonu ID kataloğu gibi kullanıcı notları vardır. Kataloğun `8D` tavşan ve `6E` topla koşan Tsubasa etiketleri yerel intro akışındaki `FB 01 8D` ve `FB 01 6E` ile; `8D` animasyon kaydı da ROM baytları ve yerel OAM iziyle uyuşuyor. Çin ROM'u farklı SHA ve 35.815 farklı bayt içeriyor; açılış scripti, palet, arka plan tablosu ve örnek animasyon verilerinin seçili aralıkları ise Türk ROM'uyla aynı. Bu, açılış animasyon etiketlerine bağımsız destek sağlar; tam oyun kodunun çözüldüğünü göstermez. Ayrıntı ve kaynaklar `reference/rom_extract/intro/online_reverse_engineering_resources.md` içinde.

Bölgesel kaynak denetimi genişletildi: Çin Hack CT2 / Ct2-Editor-Advance sayfaları düzenleyici, CHR/müzik araçları, metin tabloları ve animasyon ID kataloğu sağlıyor; erişilebilir tam Çin 6502 disassembly bulunmadı. Ayrıca Japonca wiki şu an yalnızca indeks olarak erişilebiliyor. Kullanılabilir açık 6502 kaynağı çoğunlukla Rusça yorumlu public disassembly; Türk ROM ile eşleşen ve uyuşmayan aralıklar `reference/rom_extract/intro/disassembly_coverage_audit.md` içinde sayıldı. Bu kaynakta bank 83 boş bırakıldığı için asıl açılış komut akışı yok; 512 KiB PRG/mapper-5 genişletilmiş çeviri build'i, Türk hedefinin 256 KiB PRG/mapper-4 ROM'u yerine geçmiyor. PLUS için byte-exact clean-room disassembly iddiası var ama kaynak geçici olarak private ve Japon baz sürümü Türk ROM hashinden farklı; incelenebilir kanıt değil. Çin/Türk/Japon kaynak sayfaları, yerel ROM hashleri, eşleşmeler ve adres/ofset tuzakları `reference/rom_extract/intro/regional_sources_followup.md` ile `reference/rom_extract/intro/online_reverse_engineering_resources.md` içinde.

Başlık ekranındaki kupa artık ROM sprite katmanı olarak çiziliyor: `scripts/title_cup_layer.gd` animation `$0D` tanımını, `$A7CB` frame descriptor'ını, ROM CHR'ını ve `0x00D3A0` palet baytlarını çözüyor; 63 sprite descriptor'ına başlık OAM Y=`+$30` ve öncelik-bit `$20` dönüşümlerini uyguluyor. Başlık arka plan dokuları ROM CHR'ı ile yakalanmış PPU tile/attribute yerleşiminden üretilmiş; screenshot pikselleri runtime asset değil. Sessiz bir karelik önizleme kupanın kompozisyonda göründüğünü gösterdi, ancak piksel fark ölçümü yapılmadı. Katman/öncelik tam eşleşmesi doğrulanmadığından bu bölüm de birebir kabul edilmiyor; kaynaklar `scripts/title_cup_layer.gd`, `tools/build_title_menu_background_layers.py` ve `reference/rom_extract/intro/animation_0D_sprite_palette.json` içinde.

F9 background-00 yolunda `$8BB0` ilk bir-tik loader yield'i; dönüşten sonra frame-9 RAM'deki `$0628=$39` ve dört-baytlık `$0629=$04` rezervasyonu `$9B2E` ikinci bir-tik kapasite yield'ini doğruluyor (`$39+$04=$3D`). F9 script pointer'ı `$A022`'de iki bekleme boyunca sabit kalıyor; frame 10'da F9 tamamlanıp pointer `$A024` oluyor ve FB dispatch ediliyor. İki ayrı kaynak yield'i bu replay'in F9→FB aralığını açıklıyor; kesin cycle/NMI alt-kare fazı hâlâ çözümlenmedi. Ayrıntı `reference/rom_extract/intro/f9_task_timing_trace.md` içinde.

## 2026-10-24 son doğrulama durumu

Godot 4.7.2, `--audio-driver Dummy` ile ana sahne ve son eklenen kaynak-kodlu modeller çalıştırıldı. `RomRunnerMotionRecord`, ROM `$6E` F1/F7 baytlarını ve `$975B` integratörünü kullanarak 378, 394, 395, 418 ve 419 karelerinde beklenen Q8.8 X/velocity kayıtlarını verdi. Başlık geçişi için ana sahneye Enter/Start gönderildi: 30 kare siyah, 31. karede başlık; sonra Down ile seçim değişimi. Kare 4692 `KICK OFF` ve 4694 `CONTINUE` çıktılarını FCEUX kareleriyle 61.440/61.440 RGB pikselde eşleşti.

Ana sahnedeki ROM-türevli logo çıktısı kare 13, 14 ve 26'da da FCEUX oyun pikselleriyle eşleşti. Ham yakalamada FCEUX'ün “Power on” yazısı `(2,212)-(46,220)` alanında yer aldığından karşılaştırmada yalnız bu OSD alanı dışarıda bırakıldı; dışarıdaki 61.035 pikselin tümü eşleşti. Godot çıktıları ve hash'ler `reference/diagnostics/opening_godot_verification_20261024/`, başlık geçişi çıktıları `reference/diagnostics/title_godot_verification_20261024/` altındadır.

İlk saha/koşucu örnekleri kare 380, 382 ve 394'te aynı çekirdek FCEUX referansına yalnız 84.45%, 83.94% ve 82.91% tam RGB eşleşmesi verdi; PPU fetch/banka geçişi, metin bandı ve OAM çizim sırası hâlâ fark üretiyor. Başlık kuyruğu canlı ROM/NMI komutlarını çalıştırmıyor; CPU-cycle/NMI alt-kare zamanlaması çözülmedi. ROM sürücüsünden üretilmiş müzik WAV'ının FCEUX APU/PCM kuyruğuna eşleşmesi de açık. Bu nedenle hedef **etkin** kalır; intro/field/audio bütünü birebir doğrulanmış değildir.

## 2026-10-24 devam incelemesi

- **Başlık kuyruğu düzeltmesi:** `scripts/title_rom_handoff_queue.gd` artık dokuzlu grupları sabit sayı olarak kullanmıyor; ROM'un `$3D` PPU kuyruğu sınırını ve her paketin 3-bayt başlığı + payload boyunu yürütüyor. Sonuç kaynakta gözlenen 26×9+6 paket grubuyla aynı. Palet/imleç paketi son arka plan kuyruğu boşaldıktan sonra hazırlanıyor ve başlık o paketler commit edilince açılıyor. Odaklı Godot 4.7.2 Dummy-audio harness, 240 paketin adres/sıra/içeriklerini, 30 siyah kareyi ve 31. karede açılan başlığı doğruladı; iki başlık endpoint'i FCEUX ile 61.440/61.440 RGB pikselde eşleşti. Start'ın ROM `$1E` poll'ü, ilk üretici bırakımının 3-kare fazı ve CPU-cycle NMI commit'i hâlâ kaynak koddan yürütülmüyor.
- **Koşucu/alan görüntüsü:** Kare 380/382/394 karşılaştırmaları %82.9–84.4 RGB eşleşmesinde kaldı. Yeni sessiz RAM-write izleri ROM bank-2 `$A2E8`'in `$AADF/$AAE0` ROM delta tablolarını ve scheduler fazı `$ED`'yi kullanarak `$7A–$87` scroll-event birikimlerini ürettiğini; `$A160` IRQ consumer'ının `$78` event index'iyle `$2000/$2005/$2006` raster yazılarını yaptığını gösteriyor. Kare 394'te `$7D=$01` / `$80=$04` yazımları line49/67 fine-X olaylarını üretiyor. FCEUX NewPPU kaynak incelemesi, ilk `$2005` yazımının `fh`'yi anında değiştirdiğini, ikinci `$2006`'nın aktif `v`'yi anında yüklediğini ve tile prefetch'in bunların görünür satır etkisini belirlediğini netleştirdi. Başlangıç preset'i de artık kaynaklandı: F8 `$0A` bank-2 tablosundaki `$A5DB` sözcüğünden RTS+1 ile `$A5DC`'ye giriyor; bu kod `$8895` ile `$57=0` kurup `$8920(A=5)` çağırıyor. `$9DEE` preset 5 için `$BF5F` (file `0x00DF6F`) kaydını seçiyor ve baytları gözlenen RAM başlangıç tablosuyla eşleşiyor. Task `$0D` izinde `$ED=0` geri yüklenip `$A2FD→$A2E8` delta üreticisi her gözlenen release'te çağrılıyor; runtime üretici/renderer bağlantısı ve aynı kare görüntü karşılaştırması henüz yapılmadı. Bu yüzden sabit frame-tablosu kullanılmayacak. İzler `reference/rom_extract/intro/field_runner_chr_raster_split_trace.md` ile `reference/diagnostics/raster_table_writes_20261024_212456/` ve `_213332/` altındadır.
- **Komut akışı:** Ana sahne henüz tam ROM VM'i değil. EC akış başlangıçları (`380/1120/1780/2369`), EC-02'nin 40 karelik duraklaması ve F1/FD bazı durumları capture anchor'ı olarak kalıyor. Sabit 4199-kare loop varsayımı kaldırıldı; döngü sınırı artık ROM `FE $20 $A0` komutundan izleniyor, ancak faz-8 ilk scheduler başlangıç anchor'ı sürüyor. Yeni sessiz açılış PC izi ilk `$84E7` komutunun frame 8/cycle 224.570'te, ilk NMI'ın ise frame 9/cycle 238.264'te olduğunu gösteriyor; `$0001=$08` RAM-clear pointer'ının `$C677` tarafından ilerletilmesidir. Godot frame 8'de NMI-ready biti üretmeden başlangıç ready-worker scan'ini, frame 9'da gerçek modeled NMI-ready release'ini yürütüyor; reset/main task yine tam 6502 olarak çalışmıyor. Start handoff'u da ROM'un canlı CPU/NMI işleyişi yerine modellenmiş siyah geçiş kullanıyor. Kaynak izleri `reference/diagnostics/opening_first_nmi_anchor_audit_20261024.md` ve `reference/rom_extract/intro/title_transition_pc_trace.md` içindedir.
- **Ses:** ROM sürücüsü/verisinden üretilen runtime WAV korunuyor; yakalanmış WAV runtime'a alınmadı. FCEUX 2.7.0 çıkış zinciri CPU-clock `WaveHi` örneklerini durum taşıyan 1024-tap `NeoFilterSound` FIR/resampler'ından geçirip ardından `SexyFilter` uygular. Libgme PCM'si farklı mixer/resampler yolundan geldiği için yalnızca FCEUX son filtresini eklemek kuyruğu eşleştirmiyor. Yeni build-only araç ROM-türevli NSF'i doğrudan 139.730.109 CPU çevrimi çalıştırıp PCM oluşturmadan 45.455 APU yazımını ve 4.692 PLAY çağrısını deterministik kaydediyor; 903 DMC yazımı da DMC durum/örnek modelinin gerektiğini gösteriyor. İki bağımsız iz bayt bayt aynı. İzler `reference/diagnostics/audio/rom_driver_apu_trace_20261024/`, araç `tools/audio/trace_rom_driver_apu.py`; ses runtime'ı değişmedi. Sonraki adım bu register/DPCM/cycle verisinden bağımsız APU/`WaveHi` renderer'ı kurup doğrulanmış FIR/filter zincirine bağlamak.

Bu incelemede görsel/ağır ses yolu için kanıtlı küçük bir düzeltme çıkmadı; yanlışlıkla capture-frame tablosunu runtime davranışı olarak kodlamamak için değişiklik yapılmadı. Her üç eksik de hedefin tamamlanma şartı olmaya devam ediyor.

## 2026-10-24 devamı: raster üreticisi Godot'a bağlandı

- **Koşucu/alan rasterı:** Yeni `scripts/opening/rom_raster_event_generator.gd`, ROM bank-6 preset `$BF5F` ve bank-2 `$AADF/$AAE0` delta baytlarından beş fractional accumulator ile scroll-event tablosunu üretir. `$78–$8D` frame-end RAM tablosu aynı girişli FCEUX kaydıyla source frame 378–400 arasında 23/23 karede bayt bayt eşleşti. Üretilen `$2005` fine-X ve `$2006` address-reload olayları artık `rom_ppu_nametable_screen_renderer.gd`'ye gönderiliyor. Aynı girişli Godot RGB exact oranı frame 380'de %84.45'ten %87.77'ye, 382'de %83.94'ten %86.08'e, 394'te %82.91'den %83.54'e çıktı. Kare 380 farkları y=0–143 bandında; 382/394'te alt satırlara da uzanıyor. Ayrı OAM denetimi ROM `$6E` descriptor'larını RAM OAM gölgesiyle 380/382/394 karelerinde 42/42, 41/41, 42/42 kayıtta eşleştirdi; sprite palette `$D310` da PPU `$3F10–$3F1F` ile aynı. Negatif X için gözlenen gizli-OAM kodlamasının yazan 6502 rutini hâlâ bulunmadı. Kare 380'de dot-195 MMC3 R1 yazısından sonra ilk CHR plane okumalarının dot 196/198 ve yaklaşık x=208 piksele denk geldiği kaynak-zamanlama tahmini var; renk kenarı doğrudan ölçülmedi ve kare 382/394'ün IRQ dotları farklı. PPU fetch/shifter modeli ve runtime piksel bileşimi hâlâ doğrulanmadığından görsel bölüm birebir değil. İzler `reference/diagnostics/raster_runtime_compare_1792867924/` ve `reference/diagnostics/field_runner_oam_palette_fetch_audit_20261024.md` içinde.
- **CHR cutoff denemesi:** Kaynak PPU fetch planından türetilen dot→x cutoff'ları üç karenin tanı POC görüntülerinde denendi; sonuçlar aynı POC'nin kaydırmasız görüntülerinden sıfır RGB piksel farkı verdi. POC ile runtime tabanının oranları farklı olduğundan frame 382/394'teki yüksek değerler cutoff kanıtı sayılamaz; Godot runtime'a değişiklik yapılmadı. Deneme `reference/diagnostics/chr_fetch_cutoff_candidate_20261024.md` içinde.
- **Ses/APU eşlemesi:** İzole `--cue-frame-offset 2` NSF, ilk `$58` cue ile title stop arasındaki 45.450 FCEUX APU adres/değer/yazma sırasını eşleştiriyor (903 DMC yazımı dahil); rational clock/phase uyumundan sonra en büyük zaman artığı 0.691 ms. Bununla birlikte diagnostics-only libgme WAV'ında tüm dosya korelasyonu +2 adayı için 0.90901, baseline için 0.90907; üretim WAV değişmedi. ROM stop'u frame 4662'de DMC fetch'ini durdurup pulse/noise ses düzeyini sıfırlıyor, fakat triangle ve DMC DAC latch'ini sabit bırakıyor; FCEUX'un FIR/`SexyFilter` çıkışı frame 4679'a kadar sürüyor.
  Build-only `fceux_apu_wavehi_prototype` artık FCEUX çevrim izini pulse 1/2, triangle, noise, DMC register/byte/DAC modeli, nonlinear mixer ve pinned FIR/`SexyFilter` üzerinden işler; 139.730.109 çevrimden 3.442.925 örnek üretir. DMC-free frame 283–366 penceresinde ham sample korelasyonu 0.99723, normalized RMSE %7.88; DMC’li pencerelerde ilk cue .98165, sonraki `$28` .99628, `$02` .99581, geç `$58` .93508, final `$68` .87599 ve stop tail .77007. 301 DMC start’ı bank `$1E`’de `$C000/193 B` veya `$C0C0/513 B` sample’larına eşleniyor; `$4010=$0F` 54 CPU cycle/bit seçiyor.
  DMC/sequence zamanları hâlâ yaklaşık: WaveHi prototipi DMA fırsatlarını çevrim bazında ilerletiyor, FCEUX ise instruction-hook’ta dört DMR cycle ekliyor; frame-sequencer geçişleri de instruction sınırına göre en çok 7 cycle kayabilir. Bu yüzden WAV örnek eşliği ve gerçek DMC fetch/DAC fazı doğrulanmadı. Stop frame 4662'de bütün kanalları kapatmıyor: DMC fetch durur, pulse/noise gain sıfırlanır; triangle DAC ile DMC `$4011` latch'i TND girdisinde sabit kalır, ardından FIR/`SexyFilter` kuyruğu 4679'a dek sürer. Build-only kod/çıktılar `tools/audio/fceux_apu_wavehi_prototype/` ile `reference/diagnostics/audio/fceux_apu_wavehi_prototype_20261024/`; DMC byte/adres kanıtı `reference/diagnostics/audio/dmc_playback_path_audit_20261024.md`. Godot runtime WAV değiştirilmedi.

Bu güncelleme önceki devam incelemesindeki “raster runtime'a bağlanmadı” durumunu değiştirir. Açılış hedefi etkin kalır: kaynak-komut yürütümündeki capture anchor'ları, raster fetch/IRQ fazı ve doğrulanmış runtime audio çıktısı tamamlanmadı.

## 2026-10-24 devamı: runtime ses manifesti

`scripts/opening_source_runtime.gd` artık WAV döngü başlangıcını sabit `282` değerinden almıyor; ROM sürücüsünden çevrimdışı üretilmiş ses manifestindeki ilk `$58` komut karesini ve kare hızını okuyor. Çalmadan önce manifestin sağlanan ROM SHA-256'sını, WAV yolunu, yakalanmış PCM kullanılmadığı/ROM veya emülatörün runtime'da gerekmediği işaretlerini ve WAV SHA-256'sını denetliyor. Böylece ses kaynağı değiştirilirse sessizce oynamak yerine açılış hata veriyor. `$58` karesinin kendisi hâlâ aynı-girdi FCEUX kaydından gelir; APU örnek eşliği veya bu yeni başlangıç yolu bu değişiklikten sonra Godot'ta çalıştırılarak doğrulanmadı. Kod ve açıklama `scripts/opening_source_runtime.gd` ile `docs/opening-audio-vm-bridge.md` içinde.

Paralel kaynak incelemeleri iki boşluğu daha kesin sınırladı. Sabit FCEUX NewPPU kaynağında fine-X sıfırken CHR plane okumasının çıktı tile bloğuna `+12` piksel eşlemesi ve iki-tile lookahead doğrulandı; fakat frame 382'de mapper yazısı iki plane okumalarının arasına düşüyor ve CPU izi ikinci okumada hangi bankın görüldüğünü kaydetmiyor. Bu FCEUX model eşlemesi, gerçek NES PPU'sunun ilk renk değişimini kanıtlamıyor; ayrıntı `reference/diagnostics/fceux_fetch_latch_mapping_20261024.md` içinde. Yeni sessiz açılış PC izi frame 0–12'yi kapsıyor: `$0001` RAM-clear pointer'ı `$C675` `INC $01` ile `$08`'e kadar ilerleyip `$A231`'de temizleniyor. İlk cutscene komutu frame 8/cycle 224.570'te, ilk NMI frame 9/cycle 238.264'te geliyor; NMI `$A133`'te `$001B=$C0` ready latch'ini kuruyor ve scheduler frame 9/cycle 241.107'de tarıyor. İlk worker komutu ilk NMI'dan önce çalışıyor. Godot şimdi frame 8'de ayrı non-NMI ready scan'i, frame 9'da NMI-ready release'i modellemektedir; ilk main-task scan cycle/call akışı yine kaynakta yürütülmüyor. Ayrıntılar `reference/diagnostics/opening_first_nmi_anchor_audit_20261024.md` ve `reference/diagnostics/startup_scheduler_scan_20261025_gui/README.md` içinde.

Ses incelemesi FCEUX `FCEU_SoundCPUHook` sırasını netleştirdi: frame sequencer kontrolü ve DMC DMA denemesi komut sınırlarında olur, DMR okumalarının ek çevrimleri sonraki hook'lara taşar. Mevcut trace yalnız APU yazımlarını ve frame toplamlarını içerdiğinden global sabit phase düzeltmesi kanıtlanamıyor. Gerekli hook PC/cycle, DMC iç durumları ve DMR okuma izleri `reference/diagnostics/audio/dmc_playback_path_audit_20261024.md` içinde listelendi; üretim WAV'ı ve prototip değiştirilmedi.

## 2026-10-24 devamı: Cayosa dış arşiv incelemesi

Kullanıcının verdiği Cayosa CT2 arşiv sayfasındaki 2015 veri koleksiyonu incelendi ve bulgular `reference/rom_extract/intro/cayosa_archive_review_20261024.md` ile `reference/rom_extract/intro/online_reverse_engineering_resources.md` dosyalarına kaydedildi. `Data 2015.10.6.zip` içindeki `Drama/6010-A00F 剧情完工.xls`, açılış bloğu için `$A020` işaretçisini, 641 baytlık komut akışını, Japonca metni/Çince çeviriyi ve bir GIF adını listeliyor. Bu akışın ilk 32 baytı Türk ROM'daki `0x6030` ile aynı; `+0x20` noktasından itibaren toplam 584/641 bayt farklı. Bu nedenle arşiv yapıyı ve metin bağlamını destekleyen bölgesel bir referanstır, Türk ROM'a kopyalanacak özgün kaynak değildir.

Arşivdeki `Sound/Sound.doc`, `$58` ses kimliğini açılış teması “Super Striker” olarak etiketliyor; yerel ROM ve sürücü izi gerçek sequence yolunu ayrıca doğruluyor. Animasyon/palet notları yalnızca byte veya canlı iz eşleştiğinde kullanılacak hipotezlerdir. Koleksiyon tam 6502 disassembly ya da kare-kare PC/PPU/OAM/APU yürütüm haritası sağlamıyor; ilgili sınırlar ve ROM kontrolleri Cayosa inceleme notunda yer alıyor.

## 2026-10-24 devamı: ses cue senkronu ve durdurma yolu

Godot ses köprüsü kaynak sunucunun `$58` olaylarında mevcut ROM-driver WAV'ını 282 ve 4481 karelerinden yeniden konumlandırıyor; `$68` gibi diğer olaylar ikinci bir akış başlatmıyor. Odaklı Dummy-audio harness iki `$58` anchor'ını ve `$68` no-op yolunu doğruluyor; başlık handoff stop'unu uygulayıp sahneyi serbest bırakması da artık sessizce tamamlanıyor. Zorunlu 120-kare kapatma (`godot --headless --audio-driver Dummy --path . --quit-after 120 --verbose`) exit code 0 ile çalıştı ve `AudioStreamPlaybackWAV`/`AudioStreamWAV` sızıntı uyarısı üretmedi. Kapatma sırasındaki `playing` getter uyarısını önlemek için ses çalma/durdurma/bitiş yolları açık bir durum bayrağı tutuyor; çocuk audio node'u bu bayrağa göre stop edip WAV stream'ini bırakıyor.

Ek build-only NSF→WaveHi zamanlama denemesi runtime WAV'ını değiştirmedi. ROM-driver NSF APU yazım sırası FCEUX iziyle doğrulanmış olsa da bu kez zaman damgaları FCEUX kare çevrimlerine eşlendi: küresel affine harita frame 283–366'da örnek korelasyonunu `0.96197`, DMC başladıktan sonra frame 367–450'de `-0.05478` verdi; kare başına interpolasyon aynı pencerelerde `0.58799` ve `-0.12550` verdi. Capture-write ile sürülen önceki tanı modeli karşılaştırılan aynı pencerelerde `0.99723` ve `0.98165` ölçüldü. Bu adaylar reddedildi ve üretim WAV'ı korundu. APU komut sırası eşleşiyor, fakat NSF zaman haritası instruction-boundary DMC fetch/frame-sequencer fazını yeniden üretmiyor; ihtiyaç duyulan sonraki kanıt instruction hook PC/cycle bilgisi ile DMR okuma ve DMC durum izidir. Ayrıntılar `docs/opening-audio-vm-bridge.md` ve `reference/diagnostics/audio/rom_driver_wavehi_clock_mapping_candidates_20261024.md` içindedir. Açılış sesinin örnek düzeyinde birebirliği hâlâ doğrulanmış değildir.

## 2026-10-24 devamı: tüm karelerin bellek dökümleri ve kod eşleme durumu

Kullanıcının düzeltmesi disk üzerindeki kayıtlarla doğrulandı: `reference/opening_timing_capture_20261024_131726/` FCEUX aynı-girdi replay'inde source frame 0–4692 için kesintisiz 4.693 PPU ve 4.693 RAM dump'ı içeriyor; her `frames.csv` satırının frame eşlemesi uyuyor. PPU dump'ları `$0000–$3FFF` adres görünümünü, RAM dump'ları `$0000–$07FF` CPU RAM'ini tutuyor; bunlar render edilmiş piksel kareleri veya her CHR/PPU fetch'inin dot izi değil. Seçili PPU/MMC3 olayları CPU PC/cycle ile kaydedilmiş olsa da tam 6502 instruction izi yok. Ekran dizininde 1.962 dosya girişi, 981 ham ekran yakalaması ve 981 `.uid` yan dosyasından oluşuyor; yani 4.693 karelik screenshot seti değil. Kanıt ve kapsam `reference/rom_extract/intro/frame_capture_coverage_and_mapping_status.md` içinde.

Ham PPU durumu, field runner ekranının ilk satırını açıklayan bir kaynak zinciri verdi: `$2005=$00,$FF` başlangıcı coarse-Y 31/fine-Y 7 ile `$23E0–$23FF` kuyruğunu ilk satırda tile verisi gibi okuyor; sonraki dikey artış coarse-Y 31'i 0'a sarıyor. Ayrıca `$8024 → $8464 → $84B0/$84BE → $98EA/$9953` yolu ve frame-8 bus izi, bu alana 32 adet `$55` yazıldığını doğruluyor. Godot sunucusu ROM'dan korunmuş 17 kod baytını doğrulayıp bu başlangıç durumunu modelliyor. Taze karşılaştırmada frame 380/382/394 için tam-kare RGB eşleşmesi %98.34/%96.71/%93.75; ilk 8 satırın üç checkpoint'te de 256/256 pikseli aynı. Diğer satırlar, raster bank-switch alt-kare fazı, tüm karelerin her CHR fetch'inin hangi kodla üretildiği ve ses hâlâ tam çözülmedi. Bu tek kaynak-kod→PPU→ekran dilimidir; tüm intro veya her piksel/kod eşlemesi çözülmüş değildir. Açılış hedefi etkin ve tamamlanmadı. Ayrıntı: `reference/diagnostics/field_runner_scanline0_source_render_20261024.md` ve `reference/rom_extract/intro/frame_capture_coverage_and_mapping_status.md`.

## 2026-10-24 devamı: ROM'suz Godot başlangıç denetimi

Geçici Godot proje kopyası 319 dosyayla, `.nes` dosyası ve `assets/opening/intro/` kare-görüntü dizini olmadan içe aktarıldı; 120 karelik ana sahne 0 çıkış koduyla çalıştı. Godot verbose çıktısında kaynak/nod sızıntısı uyarısı yok. Böylece bu çalıştırmada özgün ROM veya ekran görüntüsü kaynağı gerekmemesi doğrulandı. Bu henüz dışa aktarılmış masaüstü build'i veya tam açılış→başlık ses/görüntü eşleşmesi değildir. Ayrıntı `reference/diagnostics/standalone_runtime_without_rom_20261024.md` içinde; hedef etkin ve tamamlanmadı.

## 2026-10-24 devamı: ana sahne ses kaynağı ve FCEUX PCM ölçümü

`scenes/main.tscn` hâlâ `opening_source_runtime.tscn`'i başlatıyor. Bu sahne `assets/opening/audio/opening_timeline_rom_driver.wav` dosyasını runtime'da yükleyip kendi SHA-256'sını doğruluyor; kaynak sunucu `$58` cue'larını manifestteki kare 282 ve 4481'de yakalıyor. Manifestin 13 ROM-kuyruk olayı güncel ROM-driver builder olay tablosuyla 13/13 eşleşiyor; bağımsız NSF APU yazım izinin kopyası da güncel builder NSF SHA-256'sıyla eşleşiyor. Bu izler doğrulama girdisidir, runtime asset'i değildir. `godot --headless --audio-driver Dummy --path . --script tools/diagnostics/verify_opening_audio_runtime.gd --verbose` exit code 0 verdi; `$58` re-anchor, `$68` için ikinci stream açılmaması ve handoff stop/temiz sahne bırakımı geçti.

FCEUX 2.7.0 aynı-girdi PCM WAV'ı ile dağıtılan runtime WAV yeniden karşılaştırıldı: runtime WAV 3.420.937 örnek, referans 3.442.925 örnek; fark 21.988 örnek = 498,594 ms = 29,965 NES karesi. Runtime WAV kare 4661'de Start/ROM stop olayında bitiyor; FCEUX filtre kuyruğu 4679'a kadar 1-LSB üstü kalıyor ve capture kare 4692'ye kadar sürüyor. Cue-yerel RMS ölçümlerinde FCEUX kare = runtime kare + offset tanımıyla ilk müzik ve 12 pencereden 11'inde en iyi offset -1 kare, final `$68` penceresinde -2 kare; korelasyonlar pencereye göre 0,351–0,989 arasında. Örnek-dalga korelasyonu aynı kare indeksinde -0,672 ile 0,199 aralığında kaldı; farklı pencerelerin en iyi kare kaymaları da tutarlı değil. Bu nedenle cue-envelope benzerliği örnek/tını birebirliğini göstermiyor. Yöntem, giriş hash'leri ve pencere ölçümleri `tools/audio/compare_runtime_wav_to_fceux_pcm.py` ile `reference/diagnostics/audio/runtime_wav_fceux_pcm_comparison_20261024.json` içinde.

Ses kaynağı için bir manifest tutarsızlığı da bulundu: shipped WAV manifesti kaynak NSF SHA-256'sını `355c8960…` olarak yazıyor; gösterdiği `tools/audio/build/opening_timeline_rom_driver.nsf` dosyası ve aynı adlı build manifesti `2e89384e…`. Projede `355c8960…` hash'li NSF bulunamadı; güncel builder NSF'ini yeniden oluşturup aynı 3-kare libgme hizalamasıyla çevrimdışı render etmek runtime WAV ile aynı çıktıyı vermedi (`9c78eec1…` aday / `325fa794…` shipped WAV). Üretim WAV'ı değiştirilmedi. Main scene'in WAV yolunu ve cue listesini kullandığı doğrulandı, ancak şu anki WAV'ın mevcut builder NSF'inden birebir yeniden üretilebilirliği doğrulanamadı; tamamlanmadan önce kaynak manifesti/NSF geçmişi uzlaştırılmalı.

**Kaynak-artifact açıklaması:** Dağıtılan WAV, korunan `tools/audio/build/opening_timeline_unaligned.wav` ara çıktısından tam üretilebiliyor: 44,1 kHz mono PCM'de 3-frame libgme gecikmesini (2.201 örnek) atıp sonraki 3.420.937 örneği kesmek, WAV başlığı dâhil shipped SHA-256 `325fa794…` değerini verir. Ara WAV'ın SHA-256'sı `89bd6b8c…`; bu nedenle teslim edilen dosyanın baytları yeniden kurulabiliyor. Ancak ara WAV'ın bildirilen kaynak NSF'i (`355c8960…`) depoda yok; kaynak ROM'dan güncel builder ile ara çıktıyı baştan üretmek hâlâ aynı sonucu vermiyor. Bu sonuç ve crop doğrulaması `reference/diagnostics/audio/runtime_wav_fceux_pcm_comparison_20261024.json` içinde.

## 2026-10-25 devamı: açılış bütünü ve başlık denetimi

Güncel ana sahne, BG08 ortak OAM ve BG09 palet modeli eklendikten sonra 981
seyrek FCEUX ekran kontrol noktasında tekrar yakalanıp karşılaştırıldı
(`reference/diagnostics/opening_runtime_sparse_1792880258/`). RGB eşleşme
ortalaması %85,87; önplan eşleşmesi %60,27. Frame 2, kaynak ekran yakalamasının
ilk temiz görüntüden önceki başlangıç durumunu örneklemesi nedeniyle %0,17 RGB
eşleşiyor; bu tek örnek çıkarıldığında ortalamalar %85,95 / %60,33. BG09
frame 1760–2120 kümesinde 170 kontrol noktası %91,29 RGB / %83,73 önplan
eşleşmesine ulaştı; frame 2034 %89,74 / %81,76. Frame 1522 %96,41 / %92,84,
başlık frame 4692 ise 61.440/61.440 RGB pikselinde eşleşti. Bu 981 noktalı
ölçüm F8 IRQ, `$FE` replay ve BG0A kamera düzeltmelerinden önceki build'e aittir;
sonraki düzeltmelerden sonra 981 noktanın tamamı için yeni toplu ölçüm henüz
alınmadı. Seyrek ölçüm her 4.693 kareyi veya her pikselin fetch geçmişini kapsamaz;
genel açılış hâlâ birebir değil. En büyük açık kümeler F8 `$17` sunumu
frame 3600–3699, orta sahne frame 2300–2700 ve Start öncesi tekrar frame
4500–4660. F8'in eski %74,82 RGB / %0,38 önplan viewport ölçümü, text queue
beklemesi eksikken alınmış ve Godot F8 komutunu henüz çalıştırmamıştı; F8 için
görsel ölçüm sayılmamalı. F8 raster sunumu artık ROM `$A160` handler'ındaki
MMC3 `$C001` reload sayacı, `$7C` düşüşleri ve önceki NMI palette-upload yeniden
başlangıç fazından hesaplanıyor. Yenilenen 3596–3699 penceresindeki FCEUX
referansı bulunan 27 karenin tamamı RGB ve önplan piksellerinde birebir eşleşti;
3602, 3604, 3606, 3640 ve 3652 dahil. Frame 3601'in devralınmış ilk IRQ fazı ve
satır içindeki ilk piksel zamanı hâlâ açık; F8 penceresi bütün açılışın birebir
olduğunu göstermez. Son ölçüm `reference/diagnostics/f8_window_validation/match_rates.csv`,
model/evidence ise `scripts/opening/f8_title_irq_timing_model.gd` ve
`reference/rom_extract/intro/f8_00_sequence_trace.md` içindedir.

Hızlandırılmış `verify_main_opening_title_handoff.gd` denetimi Godot 4.7.2'de
başarılı: Start sonrası kaynak geçiş kuyruğu 31 karede tamamlanıp KICK OFF
başlangıç imleciyle frame 4692'de görünüyor. `verify_title_cursor_controls.gd`
Down/Up ve Select ile seçenekler arası geçişi, Start'ın seçim onaylamamasını
doğruladı. `verify_opening_audio_runtime.gd` cue 282/4481 senkronunu ve handoff
stop'unu geçti; bu yalnız ses köprüsünü doğrular, WAV örnek eşleşmesini değil.

İlk WaveHi renderer'ı ROM-driver APU olayları ve fiziksel ROM DPCM baytlarıyla
kuruldu. Pinned FCEUX 2.7.0'ın sessiz, aynı-girdi izindeki 104.106 DMC fetch'in
tamamı ROM bank `$1E` ile eşleşti. İlk prototipin düşük DMC-sonrası
korelasyonları, daha sonraki `PCM_SYNC_IN` ve `ChannelBC` model düzeltmeleriyle
azaldı; güncel ölçümler aşağıdaki 25 Ekim WaveHi devamında yer alıyor. Tanılama
WAV'ı Godot runtime'ına taşınmadı ve birebir ses olduğu doğrulanmadı.

Bu denetimler açılıştan başlığa çalışan akışı kanıtlar; bütün karelerin görsel
eşitliğini veya örnek düzeyinde müzik eşitliğini kanıtlamaz. BG09 palet
durumu seçili karelerde eşleşiyor, ancak tam ekran bileşimi ve raster fazı
henüz eşit değil. Frame-1522'deki gizli OAM slotu, başlangıçtaki kare-2 FCEUX
görüntü farkı ve sesin DMC sonrası zamanlaması da açık kalıyor.

## 2026-10-25 devamı: BG08 C1/82 ortak OAM

BG08'de `$FB 02 C1 82` ile kurulan iki nesne artık ayrı Sprite2D tahminleri
olarak değil, ROM `$9085` kayıt düzeni, F1/F7 hareketi, ROM kare tanımlayıcıları
ve ortak `$0468–$0567` OAM tamponu üzerinden kuruluyor. ROM'daki kapasiteler
C1 için 14, 82 için 56 sprite; ikinci kayıt slot 14'ten başlıyor ve 64 slotu
geçerek ilk 6 slotu eziyor. `$6E` saha koşucusu yolu değiştirilmedi.

FCEUX RAM/OAM frame 1107 ile Godot displayed frame 1108 karşılaştırmasında
64/64 OAM slotu ve 2.563/2.563 opak sprite pikseli eşleşti. Frame 1522 için
63/64 OAM slotu eşleşti; modelin ham slot 5 tuple'ı hâlâ kaynakta ölçülen
`F8 1B 00 94` yerine `4A 1B 00 94`. Görsel compositor artık yalnızca `$82`
`$AE08`/55-descriptor pozundaki kullanılmayan slot 5'i çizmiyor. Güncel aynı-
girdi recapture'da 1157–1523 aralığının tamamı 367/367 görünür RGB-exact. Slot 5'i
yazan ROM yolu ve değişken `$F7–$F9` Y baytları çözülmedi; bu bir görsel düzeltme,
ham OAM lojik aktarımı değil. Sınırlı sprite/slot karşılaştırmaları tüm ara
karelerin veya 2C02 scanline değerlendirmesinin tam eşit olduğunu kanıtlamaz.
Ayrıntı
`reference/rom_extract/intro/bg08_c1_82_shared_oam_trace.md` içinde.

## 2026-10-25 devamı: BG08 yükleme sırasındaki CHR çiftinin doğrulanması

`RomBG08RasterModel` artık F9 08 aktivasyonunda önceki BG03 R0/R1 çiftini
başlangıç durumu olarak alıyor; BG08 yükleyicisi tamamlanınca ROM kaydındaki
`$40/$00` çiftini F5 10 başlangıcına, kaynak frame 1048'e planlıyor. Yeni
`tools/diagnostics/verify_bg08_pending_pair_runtime.gd` çalıştırması frame
1047'de `$3A/$00`'ın korunduğunu ve 1048'de `$40/$00`'ın etkinleştiğini
doğruladı. Aynı-girdi frame 1050 ve 1522 görüntüleri sırasıyla %92,71 ve
%92,12 tam RGB eşleşmesi verdi. Bu geçişin özel boşluğunu kapatır; IRQ alt-kare
fazının kareler arası değişimini ve BG08 oyuncu/top OAM kompozisyonunu çözmez.
Kayıtlar `reference/diagnostics/bg08_pending_pair_1792878047/` altında; kaynak
ve kapsama notları `reference/rom_extract/intro/e8_preset_01_trace.md`,
`reference/rom_extract/intro/frame_capture_coverage_and_mapping_status.md` ve
`reference/diagnostics/frame1522_dynamic_chr_gap_audit_20261024.md` içinde.

## 2026-10-25 devamı: BG09 ROM palet animasyonu

`F5 01` BG09 palet efekti artık ekran görüntülerinden değil, doğrulanmış ROM
baytlarından çalışıyor. Bank-6 `$B802` tablo girdisinin `38 B8` işaretçisi
`$B838`'e gidiyor; korunan 18 baytlık akış `$08` taban yuvasını, dört adet
`$04` bekleme/değer kaydını (`$30,$21,$30,$25`) ve `$FE` döngüsünü içeriyor.
GDScript modeli pointer/stream baytlarını ve metadata SHA-256 değerlerini
runtime'da doğruluyor. Presenter akışı `$0633` RAM palet yazıcısına, `$9A43`
32-baytlık `$3F00` kuyruğuna ve sonraki NMI aktarımına bağlıyor.

`tools/diagnostics/capture_bg09_palette_effect_runtime.gd` ve
`verify_bg09_palette_effect_runtime.py` ile 32 checkpoint FCEUX RAM/PPU
durumlarıyla karşılaştırıldı: 1779'da RAM `$30` / PPU `$0F`, 1781'de PPU
`$30`, 1784'te RAM `$21`, 1785'te PPU `$21`; frame 2034'te RAM ve PPU ikisi
de `$25`. `$4C=$81` frame 2116'ya kadar sürer ve `$00` yalnız FD geçişinin
frame 2117 durumunda görünür. EA fade başladığında efekt kapanmıyor: frame 2104 RAM `$21` olur,
ancak dolu `$05E8` kuyruğu sonraki palet paketini `$3D` kapasite kontrolünde
bekletir. Fade PPU renkleri 2101 `$30`, 2106 `$31`, 2108 `$21`, 2111 `$11`,
2114 `$01` ve FD geçişinde 2117 `$0F` olarak yakalamayla eşleşti. Frame 2034
aynı-girdi Godot viewport'u 89,74% tam RGB / 81,76% önplan piksel eşleşmesi
verdi; pembe saha artık çiziliyor ama ekran birebir değil. Bu hedefli palet ve
NMI doğrulaması tüm karelerde kod→CHR→piksel haritası anlamına gelmiyor. Kaynak,
raw byte hash'leri ve sınırlar `reference/rom_extract/intro/bg09_pink_field_source_trace.md`
ile `reference/rom_extract/intro/frame_capture_coverage_and_mapping_status.md`
içinde; ölçüm çıktıları `reference/diagnostics/bg09_palette_effect_validation/`
altında.

## 2026-10-25 devamı: `$FE` replay ve F8 sonrası ilk `$DF` fazı

ROM `$8862`'deki `$FE $A020` handler'ı yalnız `$004D/$004E` script pointer'ını
yazıp `$84E7` yorumlayıcısına döner; PPU, ses veya sunucu durumu için genel bir
reset yapmaz. Godot sunucusu da loop'ta yalnız script cursor'ını `$A020`'ye
alır ve loop sayacını artırır; sonraki ROM komutları kendi durum güncellemelerini
uyguluyor.

F8 `$A4C0` bitişinden sonra ROM `$DF` tablosundaki 240 değerini koruyor. Kaynak
RAM frame 3967'de slot `$0005=00` ve pointer `$A29B`; frame 3968'de `$A29D` ve
slot `$0005=$EF`. Sonraki `$DF` ise frame 4226'da `$F0`, 4227'de `$EF`. Presenter,
yalnız F8 ardından gelen ilk `$DF` için bu gözlenen tek-tik fazını scheduler'a
aktaracak şekilde güncellendi; ROM komut değeri 240 olarak kalıyor. 6502'nin
kesin NMI/handler alt-kare nedeni çözümlenmiş değil. FE tekrar yürütmesi frame
4207'de `$A020`'ye dönüyor ve kaynakta F1/EC/F9 grubu 4541, F3 4577, metin 4578
ile eşleşiyor. Godot kaynak presenter'ı artık ikinci geçişte F1 komutunda
durmadan frame 4658'e kadar ilerliyor.

48 sessiz Godot kare yakalaması, frame 4468–4482 ve 4580–4658 aralıklarında
FCEUX ile karşılaştırıldı. Etkilenen 40 karede 4580–4658 RGB eşleşme ortalaması
eski kayıttaki %49,88'den %87,68'e, önplan piksel eşleşmesi %0,15'ten %74,39'a
çıktı; frame 4580 %98,05 RGB / %95,89 önplan eşleşmesine ulaştı. İlerleyen
karelerde hâlâ belirgin farklılıklar var; bu dilim birebir değil. Kareler ve
ölçümler `reference/diagnostics/replay_loop_gap_validation_20261025/` altında,
yorumlayıcı faz kanıtı ise `reference/rom_extract/intro/f8_00_sequence_trace.md`
ile `cold_start_scheduler_tick_trace.md` içindedir.

## 2026-10-25 devamı: FCEUX WaveHi ses modeli

Ses tanılama renderer'ı artık FCEUX'in tembel `ChannelBC` kanal flush sınırlarını
da modeller; ROM'dan alınan APU yazılarını, bank `$1E` DMC baytlarını, 832.848
`PCM_SYNC_IN` zaman düzeltmesini ve kare/ses güncelleme izlerini kullanır. 104.106
DMC fetch baytının tamamı ROM ile eşleşir. FCEUX karşılaştırma WAV'ıyla aynı
3.442.925 örnek uzunluğundaki tanılama çıktısında aynı indeks korelasyonu ilk
DMC öncesi 0,99759; ilk DMC cue'sunda 0,99615; `$28` dizisinde 0,99696; `$02`
dizisinde 0,99604; geç `$58`'de 0,99565; son `$68`'de 0,99663 ve duruş
kuyruğunda 0,99426 oldu. Adayın RMS seviyesi hâlâ yaklaşık %2–4 yüksek.

Bu, sesin örnek düzeyinde birebir olduğunu kanıtlamaz: CPU/DMA olay zamanlaması
hâlâ sessiz FCEUX izinden besleniyor ve tanılama çıktısı Godot runtime WAV'ına
aktarılmadı; runtime ses dosyası değişmeden duruyor. Yeni iz, karşılaştırma ve
WaveHi uygulama notları `reference/diagnostics/audio/rom_source_wavehi_channelbc_replay_20261025/`,
`reference/diagnostics/audio/fceux_dmc_hook_trace_pcm_sync_sequence_ordered_merged_20261025/`
ve `reference/rom_extract/audio/fceux_wavehi_implementation_map_20261024.md`
altında.

Runtime WAV kaynak manifestindeki NSF hash'i `355c8960…` depoda yok. WAV'in
kendisi manifestteki `325fa794…` hash'iyle sağlam; korunan unaligned ara sesin
manifestteki 3 karelik kırpımı da aynı WAV hash'ini veriyor. `355c8960…` NSF'i
üreten dosya daha sonra aynı yola yazılmış ve kayıp; mevcut `2e89384e…` NSF
12:22 UTC'de kaydedilmiş, WAV ile ara dosya ise 11:58 UTC'de oluşturulmuş.
Dolayısıyla WAV'in ara dosyadan dönüşümü yeniden kurulabiliyor, fakat onu üreten
orijinal NSF baytları yeniden üretilemiyor. Sonraki güncel builder çıktıları
ayrı tanılama klasörlerinde. Runtime varlığı değiştirilmedi. Ayrıntı
`reference/diagnostics/audio/rom_driver_rebuilt_candidate_20261025/` içinde.
FCEUX yakalamasında master volume 256, 44.1 kHz ve `soundq=2` doğrulandı; ancak
kanal ses seviyesi ayarlarının capture-anındaki config kopyası yok. Bu yüzden
WaveHi adayındaki %2–4 RMS fazlasının kaynağı kesinleşmedi; ölçülmüş kanıt
olmadan volume düzeltmesi yapılmadı. Ayrıntı
`reference/diagnostics/audio/rom_driver_rebuilt_candidate_20261025/` ve
`reference/diagnostics/audio/channelbc_volume_audit_20261025.md` içinde.

Sound test için Japonca ve Çince kaynaklar başlık ekranında A+B, ardından
Start kombinasyonunu veriyor. Japonca kaynak `SOUND 00–39` aralığını BGM,
`40–99` aralığını efekt olarak ayırıyor; bazı eski rehberlerde Select de
geçiyor. Türkçe müzik sistemi yazısındaki BGM 00–39 sıra/hedef ofsetlerinin
40'ı ROM'daki pointer sözcükleri ve bank eşlemesiyle doğrulandı. Ayrı bir
hedef-ROM bayt denetimi SOUND 40–99 efekt girişlerinin 60 pointer sözcüğünü,
sekans sonlandırıcılarını ve 189 kanal akışı hedefini de doğruladı. Bu ikinci
denetim efekt isimlerini veya ses çözümlemesini değil, ordinal→sekans/kanal
yollarını kapsıyor. Sonuçlar
[`sound_test_bgm_index_00_39.json`](rom_extract/audio/sound_test_bgm_index_00_39.json),
[`sound_test_index_audit_20261025.md`](rom_extract/audio/sound_test_index_audit_20261025.md)
ve [`sound_test_sfx_index_audit_20261025.md`](rom_extract/audio/sound_test_sfx_index_audit_20261025.md)
içinde. Bu, 40 ayrı Godot müziği veya 60 ayrı Godot efekti üretildiği anlamına
gelmiyor; runtime hâlâ açılış zaman çizgisi WAV'ını kullanıyor. Japonca
kaynaktaki A+B+Start giriş dizisi bu ROM sürümünde henüz canlı tekrar edilmedi.

## 2026-10-25 devamı: BG0A ROM kamera ve IRQ modeli

Godot artık BG0A için ekran görüntüsü/RAM değerlerini değil, ROM durumunu
izleyen modeli kullanıyor. `E8 $01`, bank-6 `$BF13` / file `0x00DF23`
preset'inden `$79=$40`, `$7C–$7E=$80,$00,$22` alanlarını kuruyor. `F9 $0A`,
bank-7 arka plan kaydı `$A1F1` / file `0x00E201` içindeki kamera kaydını
`$A227`'den okuyor: `00 21 04`. Bank-0 `$8D22/$8D88` yolu bu kaydı iki scheduler
release'ı ve Q8.8 `-0.25 px/frame` adımına çözüyor; 32 piksel taşmaları `$6A`
ile, kalan gruplar `$72` ile izleniyor. Kaynak arka plan kuyruğu frame 2367'de
tamamlanıyor ve ilk kamera güncellemesi frame 2370'te başlıyor. Seçili RAM
durumları 2367, 2370, 2570, 2580, 2680 ve 2682'de eşleşti.

Doğru kamera hareketi, alt bölüm R0/R1=`$00/$02` CHR değişimi ve aynı-girdi
149 karelik sıralı render ile RGB eşleşme ortalaması %83,17 oldu. Bu değer,
BG0A bloklarının yeni ROM-paket haritasına alınmasından ve ilk satır PPU latch
düzeltmesinden önceki aday build ölçümüdür; yeni build için güncel oran değildir.
Frame 2680/2682/2684 tam ekran eşleşmesi %77,43 / %77,34 / %81,75; alt metin
bölgeleri %99,63–100 eşleşiyor. Üst y=0–127 bölgesi kamera-only tabanıyla aynı
seviyede kaldı; hiçbir karede regresyon yok. Bu ölçümde PPUCTRL `$89` ve
PPUSCROLL Y=`$FF` renderer'a uygulanmıyordu. Sonraki ROM paket izi iki-nametablı
yerleşimi çözdü ve ilk satır latch adayını etkinleştirdi; yeni kare karşılaştırması
henüz alınmadığından yeni görüntü eşleşme oranı bilinmiyor. Bu sahnenin görsel
eşitliği tamamlanmadı. Kaynak
izi `reference/rom_extract/intro/bg0a_raster_source_trace.md`; sıralı ölçümler
`reference/diagnostics/bg0a_camera_runtime_compare_1792910385/` altında.

## 2026-10-25 devamı: dış reverse-engineering kaynakları

Japon geliştirici röportajı *Captain Tsubasa II* ara sahne sisteminin alt
yordamları olan özel bir komut dili gibi çalıştığını; hareket ve kare
sayılarının assembler biçimindeki veriyle yazıldığını doğruluyor. Japonca
binary wiki bank/adres indeksi, Çince Hack CT2 ve Ct2-Editor-Advance CHR,
müzik, düzenleme araçları ve animasyon-ID katalogları sağlıyor; kamuya açık
6502 disassembly'sinin byte-checked ortak bankları da rutin isimleri için
yararlı. Yeni 5ch part-3 postları F5/F6 ayna, F7 renk ve düzeltilmiş F9
bekleme/efekt argüman sırası için komut ipuçları veriyor. Türk açılış akışı
F9'u tek baytlı arka plan seçimi olarak kullanıyor; `$87B8` F5 handler'ı ise
`$00/$01` ile palet efektini, `$10` ile BG08 raster modelini seçiyor. Forum
notları farklı bir komut bağlamına ait görünüyor ve hedef açılışa taşınamaz.
Bu kaynakların hiçbiri Türkçe ROM için açılışın tüm karelerini veya
örnek-identik ses renderer'ını hazır sunmuyor.
Kaynak sınıfları, ROM hash karşılaştırmaları ve bağlantılar
`reference/rom_extract/intro/online_reverse_engineering_resources.md`
içinde kayıtlı.

## 2026-10-25 devamı: BG0A paket haritası ve ilk satır latchesi

Yeni NMI paket izi, BG0A `$201C` adresinin son kayıt sütunu `c=11` için
başlangıç olduğunu gösterdi. ROM kaydındaki her satır `c=11…0` sırasında
gönderiliyor; doğru yerleşim `x=(48+4*c) mod 64`. 240/240 attribute ve tile-row
paketi ROM blok baytları ve PPU hedefiyle eşleşti. Decoder, Godot packet loader
ve BG0A layout manifesti bu sıraya göre güncellendi.

FCEUX NewPPU kaynak incelemesine göre `$2000/$2005` geçici latchesi pre-render
scanline 0, dot 304'te aktifleşiyor. BG0A renderer artık `$2000=$89`, `$2005`
Y=`$FF` ve ROM kamera X değerini ilk satıra uyguluyor; önceki model X/NT-X'i
ikinci satıra erteliyor ve Y başlangıcını sıfır kullanıyordu. Yeni aynı-girdi
kare ölçümleri alttaki BG0A ve tam-açılış bölümlerinde kayıtlı; görüntü ve
açılış hâlâ birebir doğrulanmış sayılmaz.

**Kalan teslim engelleri:** (1) BG0A kalan raster/CHR split fazı, (2) Godot'un tek libgme WAV
akışını ROM komutlarıyla süren, FCEUX'ten alınmış APU/DMC timing izlerine bağlı
olmayan kaynak tabanlı oynatımla değiştirmek, (3) ses örnekleri ve mevcut 981
ekran kontrol noktasında görsel regresyonları incelemek. Müzik komutlarının
ve DMC ROM baytlarının önemli kısmı eşlenmiştir; ancak diagnostic WaveHi sonucu
yakalama zaman izine dayanır, RMS'i %2–4 yüksektir ve runtime'a bağlı değildir.
Mevcut WAV'ın tarihsel NSF hash'i depoda bulunmadığından kaynak yeniden üretimi
de açık kalır. Bu sebeple tam bit-identik teslim için güvenilir takvim verilemez;
BG0A ölçüm turu kısa vadeli bir ara adımdır, kaynak-tabanlı audio motoru ve geniş
yeniden doğrulama ise birkaç yoğun çalışma oturumu veya daha uzun sürebilir.

## 2026-10-25 devamı: BG0A düzeltilmiş harita render ölçümü

Yeni ters-sıra paket yerleşimi ve pre-render ilk satır latch modelinden sonra
Godot gerçek renderer ile sessiz çalıştırılıp 2370–2762 arasındaki 149 mevcut
FCEUX ekran checkpoint'i sırayla karşılaştırıldı. RGB tam eşleşme ortalaması
önceki build'in %83,17'sinden %93,36'ya çıktı (+10,19 yüzde puan); 149 ortak
checkpoint'in 128'i iyileşti, 21'i aynı kaldı ve hiçbiri gerilemedi. Frame 2370
%96,18; 2680 %94,70; 2682 %89,90; 2684 %94,66 eşleşti. En zayıf RGB kare 2722
%85,97 olduğundan bu sahne hâlâ birebir değil. Ölçüm
`reference/diagnostics/bg0a_camera_runtime_compare_1792911173/match_rates.csv`
ve aynı klasördeki PNG'lerde.

Bu ölçüm yalnız BG0A checkpoint aralığını kapsar. F8'in 27/27 kaynak ekran
checkpoint'i exact eşleşmesi ve title frame 4692'nin eski build'deki piksel
eşleşmesi bütün açılış için kanıt değildir. Sesin ana Godot yolu hâlâ tek libgme
WAV; sample-identical WaveHi renderer'ı ROM-komut scheduler'ı ve instruction/DMC
hook timing'iyle Godot'a bağlanmadı.

## 2026-10-25 devamı: güncel tam açılış screenshot checkpoint ölçümü

F8/replay/BG0A düzeltmelerinden sonraki Godot build'i Metal renderer ile sessiz
çalıştırıldı ve `screen_index.csv` içindeki **981 FCEUX ekran checkpoint'inin
tamamı** sırayla yakalanıp aynı-kare referansıyla karşılaştırıldı. Ortalama RGB
tam eşleşmesi %92,52; foreground exact eşleşmesi %74,25 oldu. Frame 2 hariç RGB
ortalaması %92,61. Önceki tüm-açılış build ölçümü %85,87 idi; 252 checkpoint
iyileşti, 728 aynı kaldı, 1 checkpoint (3462) %0,36 puan geriledi.

Güncel çapalar: frame 1522 %96,41; frame 2034 %89,74; BG0A frame 2680 %94,70
ve 2682 %89,90; F8 penceresindeki 27/27 checkpoint exact; replay frame 4580
%98,05; title frame 4692 %100 RGB. Kare 2'nin kaynak screenshot'ı temiz açılış
görüntüsünden önceki durumu içerdiği için %0,17 RGB eşleşiyor; bu kare hariç
ortalama ayrıca verildi.

Aralık bazında en zayıf küme frame 500–749 (%85,79 ortalama; düşük kareler
662–742), ardından 750–999 (%88,63) ve 250–499 (%89,18). Frame 1000–1499
ortalaması %96,49; 3500–3999 %98,83. Frame 4500 sonrası replay bölümü %88,11
ortalama verdi. Bu nedenle sıradaki görsel araştırma ilk yarı-intro üzerinde
yoğunlaşıyor.

Bu ölçüm mevcut 981 ekran screenshot referans setini kapsar, 4.693 PPU/RAM
bellek dökümünü veya her ara kareyi kapsamaz. Görüntü hâlâ tam birebir değildir;
kare 3462'de küçük bir gerileme ve düşük eşleşmeli sahneler incelenecek. Ölçüm
`reference/diagnostics/opening_runtime_sparse_1792911357/` altında. Ana Godot
ses yolu hâlâ tek offline libgme WAV'dır. Tarihsel NSF SHA-256 (`355c8960…`)
erişilebilir proje ve kullanıcı klasörlerinde bulunamadı; korunan unaligned WAV
mevcut runtime WAV'ını yeniden üretir, ancak kayıp NSF'i tanımlamaz. Diagnostic
WaveHi renderer captured APU/DMC/PCM timing girdileri kullanıyor, Godot runtime'a
bağlı değil ve sample-identical olduğu doğrulanmadı. Tam görsel/ses hedefi aktif.

## 2026-10-25 devamı: ROM ve emulator referansı olmayan runtime denetimi

Güncel proje kopyası `/tmp/ct2-standalone-runtime-check/` içine `.nes`,
FCEUX ekran yakalamaları, timing capture klasörleri ve tanılama çıktıları olmadan
alındı; ROM-türevli `reference/rom_extract/` kaynakları ve Godot runtime
varlıkları korundu. Godot 4.7.2 bu kopyayı içe aktarıp ana sahneyi Dummy sesle
çalıştırdı (exit 0). Aynı kopyadaki başlık kontrolü klavye ve gamepad
Down/Up/Select hareketini, başlangıç KICK OFF imlecini ve Start'ın onay
vermemesini doğruladı; ses kontrolü
WAV yükleme, `$58` re-anchor noktaları 282/4481 ve title handoff stop/scene
release yollarını geçti. Böylece `.nes` veya emulator yakalaması olmayan çalışma
denetlendi. Bu, açılış zamanlamasının ROM kaynak kodundan tam çıkarıldığı veya
görsel/ses dalga biçiminin birebir olduğu anlamına gelmez; bazı frame zamanları
hâlâ gözlenen dispatch ve capture ankrajlarına bağlıdır.

## 2026-10-25 continuation: Japanese sources, ROM-only BGM candidate, and A2 runtime check

Japanese-language research is now recorded in
`reference/rom_extract/intro/japanese_sources_opening_20261025.md` and linked
from the broader source inventory. It includes the GCGX 40-BGM/60-SFX sound
test instructions and A/B/Start controls, the Down+B opening hidden-event
lead, the Japanese address memo's opening/palette/graphics offsets with
uncertainty labels preserved, the binary wiki's bank-range menu (its public
page list currently does not expose bank-analysis pages), the developer
interview's storyboard-command-language description, and the SOUND 00–39
community catalog labels. The address memo's game-wide subjects are now also
catalogued: event/scenario and text tables, character art/palettes, action and
shot/pass animation dispatch, move records/costs, player/opponent stats, and
team tables. Its many unverified rows are summarized and linked rather than
copied wholesale. Local ROM verification status is separated from external
claims. The exact sound-test input sequence and 60 effect pointer entries have
not been replayed/audited against this Turkish ROM.

The Japanese-source inventory was expanded after opening the linked guide
indexes: it now records the San Paulo FC site's opening narration/player
introductions, seven story arcs plus cast/staff page, four gameplay-analysis
topics (Guts, through action, stat conversion, move power), and hidden-event/
story-skip claims with their cited magazine/book provenance. The reproduced
manual is indexed across 16 topics and says KICK OFF starts while CONTINUE
opens score-memo entry; progression, player roster, stat, and experience tables
are separately catalogued with revision/order caveats. It also records the
Tecmo Theater retrospective and Famicom catalog as context-only sources.
These pages provide story/mechanics labels, not a frame-to-opcode map. The
inventory defines “all” as all relevant Japanese pages found through the
documented title/binary/opening/music searches and linked indexes, not a mirror
of every Japanese webpage or verbatim copy of long transcripts/address lists.
See `reference/rom_extract/intro/japanese_sources_opening_20261025.md` and
`reference/rom_extract/intro/online_reverse_engineering_resources.md`.

A diagnostics-only BGM `$58` candidate was built from the supplied ROM's
original sound driver, Sound 00 sequence, and DPCM bank, without captured WAV or
PCM. The source pointer is verified from driver `$8BDA` at file `0x18C98`
(`AD B7`) to the Sound 00 header at `0x1F7BD`. Candidate NSF/WAV hashes, sources,
and limitations are documented in
`reference/rom_extract/audio/rom_source_bgm_candidate_status_20261025.md`.
The shipped opening WAV was not changed. This one-cue candidate is not runtime
audio yet: its absolute start frame, startup phase, and full-opening
sample-identical behavior remain unverified.

**Audio checkpoint correction:** at the frame-4661 title-stop boundary / CPU
cycle 138806913, the previous `0/1025` WaveHi mismatch and channel differences
were diagnostic comparison errors. The correctly aligned candidate range is
its final 1025 samples `[28755,29780)`; after applying the pinned FCEUX
per-channel 255/256 integer scaling, all five channel arrays, their nonlinear
WaveHi mix, FIR phase, and both `SexyFilter` accumulators match 1025/1025. The
earlier candidate-window slice compared the wrong samples. Candidate
frame-sequencer `fhcnt` remains 16032 ahead of FCEUX, so later timing can still
diverge. One internal endpoint does not prove full-opening audio. The shipped
WAV remains unchanged; see
`reference/diagnostics/audio/rom_source_wavehi_checkpoint_compare_20261025/`.

The first Godot runtime capture of ROM-derived A2 motion exposed an incorrect
expected F7 address for its repeating zero-form command; the guard was corrected
to expect `$A51A` / file `0x01452A` on ticks 2, 6, …, 46. The earlier capture in
`reference/diagnostics/a2_runtime_validation_20261025/` showed black Godot
pixels at 2376–2385, but source-state sampling and direct viewport readback
showed BG0A still rendered. A valid-size Metal readback could contain an older
draw; `capture_full_opening_runtime_reference.gd` now forces a draw, waits an
additional process frame, then reads the viewport. The corrected full capture
gives frames 2374–2385 averages of 97.12% RGB / 94.20% foreground, and
2376–2385 averages of 97.20% / 94.36%. The old black-image scores are superseded.
State and sample PNGs are in
`reference/diagnostics/a2_background_state_probe_20261025/`. The byte-verified
DMA culling mechanism is now documented in
`reference/rom_extract/intro/a2_oam_dma_culling_trace_20261025.md`: attribute
mask `$0C` makes the copier replace only DMA-source Y with `$F8`. Actual A2
per-frame call timing and the `$4014` transfer edge still need instruction-level
trace, and the 12-frame score does not establish the whole opening as exact.

## 2026-10-25 devamı: A2 OAM penceresi ve ham PPU overscan doğrulaması

Önceki tam 0–4692 ölçümü A2 ortak-satır değerlendirme kodundan önce alınmıştı;
bu ölçüm güncel A2 kodunun tüm-açılış özeti olarak kullanılmamalı. A2 değişikliği
sonrası 2367–2415 arasındaki 49 kare ayrı tekrar yakalandı. FCEUX'in görünür
224 satırında 49/49 kare tam eşleşti. 240 satırlık ham görüntüdeki 142 farklı
piksel yalnızca `y=0` satırında kaldı; görünür satırlar 8–231 tam eşleşti.
Sonuçlar `reference/diagnostics/oam_scanline_evaluation_20261025/README.md`
içinde. Bu doğrulama tüm 4693 kareyi A2 sonrası tekrar ölçmediği için açılışın
genel görsel tamlığını kanıtlamaz.

## 2026-10-25 devamı: ROM/emülatörsüz güncel açılış ve menü denetimi

Güncel kaynaklardan ayrı `/tmp/ct2-standalone-current/` çalışma kopyası
oluşturuldu; bu kopyada `.nes`, emulator PPU/RAM/screenshot kayıtları ve
`reference/opening_reference_capture/` yok. Godot 4.7.2 projeyi yeniden içe
aktardı ve varsayılan `main.tscn` 10 kare boyunca sessiz başlatıldığında çıkış
kodu 0 oldu. Aynı izole kopyada `verify_main_opening_title_handoff.gd`, ana
sahnenin 4692. kaynak karede KICK OFF üzerinde duran, seçenek onaylamayan
başlık ekranına ulaştığını doğruladı. `verify_title_cursor_controls.gd` klavye
ve gamepad Down/Up/Select hareketini ve Start'ın onaylamadan kalmasını;
`verify_opening_audio_runtime.gd` WAV yükleme/çalma, iki `$58` yeniden eşleme
noktası ve geçişte durdurmayı doğruladı. Bu testler runtime'ın ROM/emulator
dosyalarına bağımlı olmadığını ve akış/menü kablolarını gösterir; Godot WAV'in
FCEUX dalga biçimiyle örnek örnek eşleştiğini veya tüm introyu görsel olarak
doğruladığını göstermez. Ses zamanlaması ve örnek dalga biçimi hâlâ açık.

## 2026-10-25 devamı: piksel üretim optimizasyonu ve aynı-kare kontrolü

`rom_ppu_nametable_screen_renderer.gd` ROM CHR desenlerini başlangıçta piksel
indekslerine çözüp saklıyor, tile/attribute okumalarını tarama satırı içinde
önbelleğe alıyor ve her piksel için `Image.set_pixel()` çağrısı yerine RGBA
bayt tamponu fallback'ı duruyor. Üretim varsayılanı 8×1 CHR/palet satırlarını
önbelleğe alıp `Image.blit_rect()` ile tile/fetch sınırlarında kopyalıyor; MMC3
raster bank değişimleri satır ortasında ayrı span olarak işleniyor. 2367–2408
penceresinde tam presenter ortalaması 234,679 ms'den 34,560 ms'ye indi; medyan
156,462 ms'den 25,006 ms'ye, p95 449,855 ms'den 65,537 ms'ye indi. Güncel
GDScript piksel fallback'ı 102,082 ms ortalama. 42/42 background doku hash'i
iki yol arasında aynı. 60,1 Hz hedefi olan yaklaşık 16,6 ms/kare hâlâ sağlanmadı;
34,6 ms headless source-update ölçümü canlı oynatma hızı değildir.

Değişiklikten sonraki gerçek 256×240 viewport yakalaması 2367–2415 penceresinde
ayrıca FCEUX ile karşılaştırıldı: görünen 224 satırda 49/49 tam RGB eşleşme.
Ham 240 satırda 142 farkın hepsi y=0; alt 8 satırda da fark yok. Kareler ve
metrikler `reference/diagnostics/oam_scanline_evaluation_20261025_post_renderer_optimization/`
altında; performans ölçüm yöntemi
`reference/diagnostics/opening_render_performance_optimization_20261025.md`
içinde.


## 2026-10-25 devamı: 2511–2592 EC `$04` animasyon farkının kaynağı

Sol-alt karakterin küçük kalıntısı statik CHR/palet/nametable çözüm hatası değil.
FCEUX RAM/PPU snapshot'larında `$2302/$2303/$2322/$2323` hücreleri 2511 ve
2550'de `DD B5 F5 DB`, 2592'de `DD B5 DF DB`. Godot'un aynı gösterim karelerinde
ise sırasıyla `DC B5 DF EC`, `DE B5 F5 F0`, `DC B5 DF EC`. Attribute `$55/$55`,
palet ve alt CHR bankları `[0,1,2,3]` iki tarafta aynı; bu alanda sprite yok.
Fark EC `$04` akışının animasyon kayıtlarının kare/producer zamanlamasında:
FCEUX `$0652/$0653` değerleri 2511'de `8C/03`, 2550'de `89/03`, 2592'de `86/01`,
Godot'ta `81/02`, `89/01`, `8A/03`. Renderer doğru canlı PPU hücrelerini okuyor;
fark animasyon tile verisinin hangi kaynak karede kuyruğa verildiğinde. Kaynak
scheduler'ın runnable/yield aralıkları henüz çözülmedi; bir kare kaydırma gibi
görsel override uygulanmadı. PC-tagged `$8A0F`/NMI iziyle kaynaklı düzeltme
araştırılıyor.


## 2026-10-25 devamı: kaynak NMI'dan NSF PLAY fazı

ROM reset/NMI yolundan `$C421` servisinin bank-2 `$A000` yordamını çağırıp
`$C449`'da sound-driver `$8000` girişine geçtiği byte-checked trace ile takip
edildi. Soğuk açılıştaki ilk NMI frame 9/cycle 238264; kaynak-only NSF PLAY
index 7 cycle 238240, sonraki frame 10/index 8 de 23 cycle farkla aynı çerçeveyi
veriyor. `$ED` frame F isteğinin sonraki NMI'da tüketilmesi wrapper başlangıç
seed'ini 3 yerine 1 olarak türetiyor. Seed-1 tanı NSF'inde ilk APU yazısı FCEUX
izinden 1.221 cycle erken; önceki seed-3'te 60.781 cycle erkendi. APU
adres/değer/sıra 45.450/45.450 eşleşti (903 DMC kayıt yazımı dahil). Birkaç
pencerenin müzik zarfı frame hizası +2'den 0'a geldi; ancak PCM korelasyonu
karışık ve tüm dosyada yalnız 0,0194. Cue event kareleri hâlâ kısmen capture
anchor'lı olduğundan runtime WAV/manifest değiştirilmedi. Dosyalar
`reference/diagnostics/audio/cold_start_rom_to_driver_play_phase_20261025.md`
ve `reference/diagnostics/audio/source_phase_seed1_candidate_20261025/` içinde.

## 2026-10-26 devamı: EC bekleme düzeltmesiyle ROM'suz açılış doğrulaması

Son değişen `cold_start_source_command_presenter.gd`, daha önce `.nes` ve
emülatör yakalamaları olmadan kurulmuş izole `/tmp/ct2-standalone-current/`
kopyasına taşındı; bu kopyada `.nes` dosyası sayısı 0 ve sunumcu hash'i çalışma
alanındaki dosyayla aynı. `verify_main_opening_title_handoff.gd` başlık kuyruğunu
frame 4692'de KICK OFF başlangıç imlecinde tamamladı; seçenek onaylanmadı.
`verify_title_cursor_controls.gd` klavye ve gamepad Up/Down/Select hareketini
doğruladı, Start da onaylamadan kaldı. Bu son kod değişikliği için ROM'suz
çalışma/menü kontrolünü doğrular; müzik örnek eşleşmesini, gerçek CPU/NMI
geçiş fazını veya tüm açılışın görsel tamlığını kanıtlamaz.

## 2026-10-26 devamı: kalan görsel farklar ve ses üretim zinciri denetimi

Güncel tam FCEUX/Godot karşılaştırmasında kalan 45 piksel, 18 kareye dağılıyor;
konumlar `reference/diagnostics/opening_residual_pixel_locations_20261026.md`
içinde listelendi. Farkların çoğu aynı kısa `$0D` koşucu animasyonundaki sprite
örtüşme pikselleri. İki hedef piksel için FCEUX yazılım izinde sprite plane
okumalarıyla aynı aralıkta `$2006` yazıları görülüyor; bunlar fiziksel 2C02
fetch kuralını kanıtlamadığından Godot'a koordinat düzeltmesi eklenmedi.
Kaynak izinde güvenle genellenebilir bir bank-kilidi veya OAM-sırası kuralı
henüz bulunmadı. Ayrıntı: `reference/diagnostics/godot_sprite_overlap_source_audit_20261026.md`.

Arka plan GPU çizici POC'sindeki eski BG01 uyuşmazlığı, ROM CHR banka
numaralarını taşıyan uniform değerinin shader'da yanlışlıkla tekrar 255 ile
çarpılmasından kaynaklanıyordu. Düzeltme 53/53 örnek kareyi yazılım arka plan
çizimiyle aynı yaptı. Ardından çizici çalışma zamanına taşındı ve desteklenen
yerel Godot render yöntemlerinde varsayılan oldu. Headless/uyumsuz render
yönteminde, kurulum hatasında veya kare başına sekizden fazla MMC3 CHR yazımında
yazılım satır-çizimine otomatik düşüyor; karşılaştırma için
`set_force_software_renderer_diagnostics(true)` anahtarı duruyor.

GPU yolunu varsayılan yapmadan önce alınan tam 0–4692 yakalamasında 4693/4693
kare yazılım çizimiyle RGB olarak eşleşti; fark yok, görüntü önbelleği yeniden
kullanımı yok ve fallback yok. Bu yakalama aynı GPU kod yolunu kullandı, ancak
üretim varsayılanına geçişten önce alındı. Refaktör sonrası 53 temsilî kare
yeniden ölçüldü: 53/53 RGBA hash eşleşmesi, sıfır RGB farkı ve sıfır backend
hatası. Ana sahnenin başlık devri ile klavye/oyun kolu imleç kontrolleri ve
ROM/emülatör yakalamaları çıkarılmış bağımsız kopya doğrulandı; bu headless
kontroller otomatik yazılım fallback'ini kullandı.

Görüntü okumadan yapılan yerel pencere ölçümünde, 2367–2408 arasındaki 42 karede
yazılım ortalaması 33,772 ms, GPU ortalaması 7,139 ms oldu; GPU'da 42 karenin
1'i 16,639 ms NTSC kare bütçesini aştı (en yüksek 51,730 ms). Bu kısa pencere
ölçümü tam açılışta sürekli 60 Hz veya başka grafik sürücülerinde aynı sonucu
kanıtlamaz. Bu GPU testleri yazılım çizimiyle eşitliği ölçer; FCEUX/gerçek PPU
eşitliğini, kalan açılış görüntü farklarını veya ses eşliğini çözmez. Ayrıntı:
`reference/diagnostics/gpu_bg_modes_poc_20261026.md`.

Ses denetiminde runtime WAV'ın JSON'u gerçek dosyada bulunmayan eski bir NSF
SHA-256'sı gösteriyor; güncel NSF builder aynı WAV'ı yeniden üretemiyor.
Runtime WAV/manifesti korunuyor. Aynı zamanda builder varsayılanı seed 3,
ROM NMI izinin desteklediği PLAY fazı seed 1; `$4010/$4017` için 1134-cycle
gecikme FCEUX callback çevrimlerine göre ayarlanmış, ROM instruction akışından
çıkarılmış değil. Dolayısıyla müzik ROM'dan türetilmiş olsa da üretim zinciri
tekrar üretilebilir ve örnek eşliğinde değil. İlk uygulanabilir adım, ROM
instruction akışından cold-start ses giriş fazını çıkarmak; sonra APU/DMC
çevrimlerini ve NSF/WAV build lineage'ını yeniden kurmak. Kanıt ve öneri:
`reference/diagnostics/audio/rom_only_audio_next_step_audit_20261026.md`.
Bu bulgular goal completion'ı engeller; görüntü/ses tamlığı veya hedef 60 Hz
oynatma doğrulanmış sayılmaz.

## 2026-10-26 devamı: soğuk resetten ilk komuta kaynak izi

İki ayrı sessiz/offscreen FCEUX çalıştırması ROM resetinden ilk cutscene komut
adımına kadar aynı CPU çevrimlerini ve iki `$2002` vblank kenarını tekrarladı.
`$FFF0` reset stub'ı `$C64E` kurulumuna gider; oradaki iki `LDA $2002 / BPL`
beklemesi vblank'i ROM davranışıyla senkronlar. İlk literal `$9EED` scheduler
tarama PC'si FCEUX frame 7 / cycle 199901, ilk `$A020` interpreter adımı frame
8 / cycle 224570, ilk NMI frame 9 / cycle 238264. Cutscene byte'ları `$A020`'den
başlayıp `$ED $58`'e ROM scheduler tick 274 / frame 282'de ulaşıyor; ilk cue
frame'i capture'dan çalışma zamanı olay listesine alınmıyor.

Bu iz, frame 8/9'u ROM komut akışı ve ölçülen FCEUX power-on fazıyla açıklar;
ROM tek başına “sekiz kare bekle” sabiti içermez. İlk iki vblank'in mutlak
zamanı başlangıç PPU fazına bağlı, FCEUX Lua çekirdeği de scanline/dot
koordinatı vermiyor. Dolayısıyla sunumcudaki başlangıç kare ankrajları şimdilik
korunuyor; bunları kaldırmak için ölçülen başlangıç fazını açıkça modelleyip
CPU-frame convention farkını karşılaştırmak gerekiyor. Ayrıntı ve iki trace:
`reference/rom_extract/intro/cold_start_first_ed58_frame_anchor_audit_20261026.md`
ve `reference/diagnostics/cold_start_reset_path_20261026_121525/`.

## 2026-10-26 devamı: seed-3 ROM/NSF WaveHi başlangıç adayı

ROM/NSF-only tanılama adayı, sentez sırasında yakalanmış FCEUX APU/DMC çevrimlerini,
kare zamanlarını veya PCM'i kullanmadan üretildi. Girdiler ROM/NSF'ten türetilen
45.457 APU yazımı, 4.701 PLAY sınırı, fiziksel ROM bankası `$1E`'deki DPCM
baytları ve sabitlenmiş FCEUX mikser/filtre uygulamasıdır. WAV yalnızca sonradan
karşılaştırma için okundu. Aday 3.449.576 örnek; FCEUX referansından 6.651 örnek
(0,151 sn) uzun.

Aynı örnek indeksindeki tüm-kayıt korelasyonu 0,02453 ve örnek eşleşme oranı
%15,87. İlk DMC öncesi pencerede doğrulama sırasında ölçülen, adaya uygulanmayan
1.497 örnek kaydırma korelasyonu 0,92382'ye çıkarıyor; daha sonraki pencerelerde
en iyi kayma tutarlı değil. Bu nedenle tek bir gecikme düzeltmesi tüm müziği
eşleştirmiyor ve aday örnek-doğrulanmış değil. DMC modeli ilk 478 ROM baytında
libgme callback adres/değer dizisiyle uyuşuyor, ardından stop/restart çevresinde
ayrışıyor: model `$C0C0=$95`, callback `$C29E=$AA`; toplamlar 104.179 ve
104.187. Eksik parça, CPU komut sınırında DMC DMA fırsatı, halt/alignment/read
stall çevrimleri ve `$4015` stop/restart sırasında pending fetch durumudur.
Callback çevrimleri sentez girdisi yapılmadı; bunlar donanım bus-fetch zamanını
kanıtlamıyor.

Bu aday yalnızca tanılamadır; runtime WAV, manifest ve Godot audio kaynağı
değişmedi. Bundan sonraki kaynak-tabanlı ses işi, ROM instruction/NMI fazından
ilk PLAY mutlak başlangıcını türetmek ve DMC DMA/restart durumunu komut çevriminde
modellemektir; sonra WaveHi karşılaştırmasını yeniden çalıştırmak gerekir.
Detay/ölçümler:
`reference/diagnostics/audio/source_nsf_wavehi_rom_dmc_20261026/README.md` ve
`validation_comparison.json`.

## 2026-10-26 devamı: seed-1 WaveHi faz karşılaştırması

Önceki adayın seed 3 başlangıcı, ROM/NMI izinin desteklediği seed 1 ile aynı
WaveHi modeli kullanılarak yeniden üretildi. Seed 1 ilk eşleşen APU yazımını
FCEUX doğrulama izine 1.221 CPU çevrimi yaklaştırıyor; seed 3'te fark 60.781
çevrimdi. Ortak örnek uzunluğunda aynı-indeks korelasyonu 0,02453'ten 0,10834'e,
örnek eşleşme oranı %15,87'den %16,06'ya yükseldi. DMC öncesi ilk müzik
penceresinde korelasyon −0,52580'den 0,61093'e çıktı; doğrulama-only en iyi
kayma +1.497'den +28 örneğe düştü. Bu kayma WAV'a uygulanmadı. DMC sonrası
pencerelerde faz ve korelasyon hâlâ tutarsız; tüm parça örnek-doğrulanmış değil.

ROM DPCM fetch modeli seed 1'de ilk 18.886 byte için NSF callback
adres/değer sırasıyla uyuşuyor; stop/restart bölgesinde callback'in fazladan
`$C2A5=$AC` fetch'i modelin `$C000=$AA` isteğinin önüne geçiyor. Model 104.190,
callback izi 104.188 fetch bildiriyor. Callback timestamp'leri sentez girdisi
değil. CPU komut sınırı DMA duraklamaları ve stop/restart state'i hâlâ
çözülmeli. Aday ve ölçümler:
`reference/diagnostics/audio/source_phase_seed1_wavehi_20261026/README.md` ve
`validation_comparison.json`. Üretim WAV/manifest/runtime sesi değişmedi.

## 2026-10-26 devamı: animasyon kaynak önbelleği ve sahne döngüsü

Sprite animasyon düğümleri her ROM FB setinde yenileniyor; önceki kod her yeni
düğüm için 128 KiB CHR'ı okuyor, yaklaşık 947 KiB JSON'u ayrıştırıyor ve tüm
sprite-frame adres haritasını yeniden kuruyordu. `rom_sprite_animation_prototype.gd`
artık ROM CHR/paleti, parse edilmiş değişmez JSON'u ve ortak frame-adres
haritasını script sınıfı düzeyinde önbelleğe alıyor. Bu, node başına tekrar
okuma/parse/map kurulumunu kaldırır; sprite rasterizasyonunun veya tüm oyun
karelerinin 60,0988 Hz'de yetiştiğini henüz kanıtlamaz.

`scenes/main.tscn` tek bir `OpeningSourceRuntime` çalıştırır; proje kodunda
`change_scene`/scene reload yolu bulunmadı. ROM `$FE $20A0` komutu frame 4207'de
logo dizisine döner; yaklaşık 70 saniye sonra logonun yeniden görünmesi ROM
akışındaki döngüdür. Start'ta aynı sahne sunucusu gizlenir, 30 siyah kare
gösterilir ve başlık menüsü görünür olur. Cache değişikliğinden sonra
`verify_main_opening_title_handoff.gd` frame 4692'de onaysız KICK OFF başlangıç
seçimiyle geçti; `verify_title_cursor_controls.gd` klavye/oyun kolu
Down/Up/Select'i ve Start onaysız kalmasını geçti. Bu testler açılış tüm-kare
görüntü eşleşmesini, canlı GPU performansını veya müzik waveform eşleşmesini
kanıtlamaz. Kaynak denetimi `scripts/opening_source_runtime.gd:101-137` ve
`reference/diagnostics/gpu_bg_modes_poc_20261026.md` içinde.

`profile_opening_runtime_realtime.gd`, Godot 4.7.2'nin sessiz native GL
Compatibility/Metal penceresinde source frame 0–4661'i yürüttü: 77,336 sn,
9.197 host-frame örneği, ortalama 8,409 ms, p95 14,060 ms. NTSC 16,639 ms
bütçesini 20 host aralığı aştı; en uzun aralık 166,277 ms. 24 kaynak kare
sonraki host adımlarına yakalandı (en yüksek tek ölçüm adımı 9); GPU arka planı
aktifti ve fallback sayısı sıfırdı. 25 ms üzerindeki aralıkların başlıcaları
frame 19→20'de `$8D` logo, frame 1046→1047'de `$C1/$82` BG08 ve frame 3554→3555'te
`$0D` BG0B geçişleriydi. Ölçüm, özellikle ilk görünür logo karesinde aralıklı
takılma kaldığını gösterir; sebebin shader ilk çizimi mi sprite dokusu üretimi
mi olduğu ayrıştırılmadı. Bu bir native 120 Hz pencere ölçümüdür; Godot editörü
debugger'ına bağlı oynatımın veya başka monitör/GPU'ların hızı değildir. Profil
komutu ve detaylı olaylar `tools/diagnostics/profile_opening_runtime_realtime.gd`
içinde; kapanışta Godot iki ObjectDB/resource kullanım uyarısı verdiğinden test
aracı temiz kaynak bırakımı açısından da iyileştirilebilir.

## 2026-10-26 devamı: ROM sprite rasterizasyonu önbelleği

`scripts/opening/rom_sprite_animation_prototype.gd`, ROM CHR/palette verisinden
üretilen 8×8 RGBA tile varyantlarını tembel biçimde önbelleğe alıyor ve
scanline/OAM görünürlüğünü koruyarak ters OAM sırasıyla `Image.blend_rect`
kullanıyor; önceki piksel-piksel renderer doğrulama/fallback yolu olarak kaldı.
Frames 0–4661'deki 793 farklı sprite pozu iki renderer arasında sıfır pixel
farkıyla eşleşti; önbellek en çok 3.763/8.192 giriş kullandı. 13 hedefli native
aynı-girdi kare yakalaması önceki Godot baseline'ıyla piksel piksel aynıydı.
FCEUX'e karşı, belgelenmiş başlangıç OSD maskesi sonrası 12/13 kare tam aynı;
frame 3555'te önceki Godot baseline'ında da bulunan bir piksel farkı kaldı.
Başlık handoff ve klavye/gamepad imleç doğrulamaları geçti.
Tekrarlanabilir headless denetim
`tools/diagnostics/verify_sprite_tile_cache_parity.gd` olarak eklendi; son PASS
raporu `reference/diagnostics/sprite_tile_cache_parity_20261026.json` içinde
793 poz, sıfır RGBA uyuşmazlığı ve ROM/emülatör runtime bağımlılığı olmadığını
kaydediyor.

Headless poz ölçümlerinin medyanı `$8D` için 0,825→0,290 ms, `$0D` için
1,623→0,232 ms, `$82` için 1,800→0,212 ms, `$C1` için 0,631→0,064 ms oldu.
Bunlar sprite CPU rasterizasyon ölçümleridir; ilk GPU texture upload'ını ya da
canlı native pencerenin tüm kare hızını kanıtlamaz. Önceki 166 ms açılış
takılmasının giderildiği söylenemez. Tile varyantları runtime için ROM CHR/paletten türetilir;
emülatör screenshot'ı veya capture WAV kullanılmadı. Bu değişiklik yeni ses
içeriği üretmedi ve production WAV'ı değiştirmedi.

Tile-cache sonrası sessiz native-window profili source frame 4661'e ulaştı:
77,419 sn, 9.212 host aralığı, ortalama 8,404 ms, p95 14,443 ms, NTSC 16,639 ms
bütçesini aşan 21 aralık, en uzun 258,016 ms. Kaynak adımlayıcı 26 kareyi
sonraki host adımlarına yakaladı; maksimum tek adım 9 kareydi. En uzun takılma
ilk `$8D` logo pozunda frame 17→19 arasında oluştu; sonraki büyük aralıklar
1046→1047 BG08'de 33,689 ms, frame 3344 `$0D` animasyonunda 31,991 ms ve
3554→3555 BG0B geçişinde 27,993 ms oldu. Ortalama hız gerçek zamanlıya yakın,
ama poz rasterizasyonu iyileşirken en büyük ilk-kullanım takılması çözülmedi;
GPU upload/zamanlayıcı etkisi ayrıştırılmadı. Profil sessiz ses sürücüsüyle
çalıştı; bu ölçüm debug editöründe veya farklı donanımda aynı hızı garanti etmez.

258 ms olayını ayırmak için `tools/diagnostics/profile_first_logo_native_startup.gd`
ile kısa ve ön ısıtmasız native ölçüm yapıldı. Bu koşuda 17/18/19 karelerinde
sprite render CPU süreleri 0,938/0,927/0,431 ms, texture oluşturma/submit
0,214/0,208/0,080 ms oldu; ilk `$8D` ROM veri yüklemesi frame 10'da 19,003 ms
sürdü. 258 ms takılma tekrarlanmadı. Ana sahne kaynak yüklemesi 217 ms, node
ready işlemleri 182 ms, ilk native çizim 23 ms sürdü (~423 ms script
başlangıcından ilk çizime). Aynı kısa koşuda başka sunum beklemeleri frame 3'te
57 ms ve frame 8'de 126 ms'ye çıktı; bu scheduling/presentation jitter'ını
gösteriyor ama önceki 258 ms olayının sebebini kanıtlamıyor. Godot ayrı GPU
texture-upload süresi vermedi. Ölçüm `reference/diagnostics/sprite_first_logo_native_timing_20261026.json`
içinde; varsayılanı kapalı diagnostic sink render kararlarını değiştirmiyor.

## 2026-10-26 devamı: ROM DMC fetch sırası için tekrarlanabilir doğrulama

`tools/audio/compare_source_dmc_fetches_to_fceux.py`, seed-1 ROM/NSF-only WaveHi
adayının DMC ROM okuma sırasını aynı girdili FCEUX DMA trace'iyle üretimden sonra
karşılaştırır; PCM okumaz ve FCEUX zamanlarını sentez girdisi yapmaz. Adayda
104.190, FCEUX trace'inde 104.106 fetch var. İlk 477 adres/değer çifti aynı;
indeks 477'de model `$C29D=$D5` isterken FCEUX `$C0C0=$95` ile yeni örneğe
başlamış. Bu, ROM `$4015=$0F/$1F` stop/restart sınırındaki DMC timer/refill fazı
farkıdır; renderer'ın status yazısında state temizliğini yanlış yaptığını
kanıtlamaz. Kaynak model buffer/shift durumunu koruyor; açık iş CPU komut
sınırındaki DMA refill ve dört-cycle stall sırasını modellemek. FCEUX çevrimleri
yalnızca doğrulamadır; WAV üretiminde kullanılmadı.

Libgme callback-zamanlarını WaveHi DMC zamanlayıcısı olarak kullanan ayrı aday,
104.188 callback olayını ROM bankası `$1E` ile adres/değer bazında doğruladı ama
callback çevrimleri DMA bus çevrimi değil. Per-cycle model callback dizisiyle
ilk 18.886 fetch boyunca eşleşiyor; sonraki farkta callback eski örnekten
`$C2A5=$AC` baytını ROM stop yazısından 93 cycle önce raporlarken model yeni
örnek `$C000=$AA` refill'ini stop'tan sonra tahmin ediyor. Tam örtüşme
korelasyonu 0,10303 oldu; önceki per-cycle adayın 0,10834 değerinden düşük.
Callback adayı da tanılama olarak kaldı. Production WAV, manifest ve çalışma
zamanı ses kaynağı değişmedi. Ayrıntılar
`reference/diagnostics/audio/seed1_dmc_stop_restart_index477_audit_20261026.md`
ve `reference/diagnostics/audio/source_phase_seed1_nsf_callback_wavehi_20261026/`
içinde.

## 2026-10-26 devamı: ilk ROM ses kurulumu ve güç-açılış fazı

ROM `$C64E` başlangıcı iki başarılı `$2002` vblank yoklamasını bekliyor;
ikinci yoklamanın çıkışından `$C685` APU kurulumuna kadar kaynak kodu
22.635 CPU çevrimi veriyor. Pinned FCEUX 2.7.0'da `newppu` kaynak varsayılanı 0
olsa da `--no-config` varsayılan config'i yükler, yalnızca kaydetmeyi kapatır.
Bu makinedeki `~/.fceux/fceux.cfg` `SDL.NewPPU=1` içeriyor ve pinned SDL kodu
bunu etkinleştiriyor. İlk başarılı `$2002` okuması cycle 59.572'de; bu New PPU
başlangıcıyla uyumlu. Captured trace canlı değişkeni ayrıca kaydetmediğinden
bu atıf launch/config/source kanıtına dayanıyor. New PPU CPU instruction edge'i
henüz adımlanmadı; NSF seed-1 adayındaki 1.134-cycle düzeltme doğrulama/fit
bilgisi olarak kalıyor ve runtime sesine uygulanmıyor. Ayrıntı ve pinned source
linkleri `reference/diagnostics/audio/old_ppu_poweron_phase_audit_20261026.md`;
ROM reset izi `reference/rom_extract/intro/cold_start_first_ed58_frame_anchor_audit_20261026.md` içinde.

## 2026-10-26 devamı: reset CPU/PPU fazı adımlandı

Bir ROM/CPU/PPU source stepper, New PPU için 17.019 reset-hook satırını eşleştirip
`$C685`'i cycle 111.984'te, `$4010/$4017` yazımlarını 111.988/111.994'te
türetti; kayıtlı FCEUX değerleri yalnızca son doğrulama olarak kullanıldı. Old
PPU alternatifinde bu kenarlar 112.096 ve 112.100/112.106'dır. `--no-config 1`
varsayılan config'i yüklediği ve yerel `SDL.NewPPU=1` olduğu için iz New PPU'yla
uyumludur, fakat capture canlı PPU değişkenini kaydetmedi. Bu sonuç ilk
reset/VBlank/APU-kurulum fazını çözer; Godot sunumundaki sonraki frame-8/9
worker/NMI anchor'ları ve standalone APU/DMC sesi hâlâ tam source-executed değil.
Production ses değişmedi. Ayrıntı:
`reference/diagnostics/audio/old_ppu_poweron_phase_audit_20261026.md` ve
`reference/rom_extract/intro/cold_start_first_ed58_frame_anchor_audit_20261026.md`.

## 2026-10-26 devamı: ilk `$ED $58`'e kadar ROM CPU/PPU adımı

Tanılama amaçlı ROM/CPU/PPU adımlayıcı `$C685` sonrasından worker kurulumuna,
ilk NMI/ses sürücüsü çağrısına ve MMC3 raster IRQ'larına kadar ilerledi. New PPU
kaynak sırasından türetilen `$84E7` komut adımı, `$A02A` konumundaki `$ED $58`
verisini frame 282, cycle 8.393.008'de okuyor. Saklı FCEUX olay kaydı frame 282
ve `$58` ses kimliğini doğruluyor; bu komut için mutlak CPU-cycle hook'u
kaydetmediğinden 8.393.008 doğrudan capture karşılaştırması değil, ROM/source
model sonucu olarak kalıyor. İlk `$4015=$0F` yazımı frame 283, cycle 8.400.582'de
çıktı ve saklı FCEUX bus callback'iyle tam eşleşti. Kaynak sprite-slot-2 IRQ
modeli de `$C506` girişlerini 255.169 ve 284.952'de yeniden üretti.

Bu sonuç kaynak zamanlamasını ilk ses-enable kenarına kadar doğrular; Godot
sunumuna henüz aktarılmadı ve tam WAV/PCM eşleşmesini kanıtlamıyor. Çalışma
zamanı kodu ve production ses değişmedi. Ayrıntı ve karşılaştırma sınırları:
`reference/diagnostics/audio/cold_start_source_cpu_ppu_stepper_extension_20261026.md`.

## 2026-10-26 devamı: tüm ses komutları ve tam ROM ses izi

Tanılama amaçlı New-PPU/CPU adımlayıcısı kaynak komutlarını frame 4662'ye kadar
yürütüp 12 `$ED` ses komutunun tüm frame/ID çiftlerini ve Start girdisiyle
frame 4661 `$8048` `$01` Stop yolunu üretti. 12 çift retained `$0700` olaylarıyla
eşleşiyor; bu liste ilerletme girdisi değil, sonradan doğrulama oracle'ıdır.
İlk `$ED $58` frame 282 / cycle 8.393.008'de source-derived, fakat o komutun
CPU-cycle hook'u yakalamada yok. İlk DMC enable `$4015=$0F` frame 283 / cycle
8.400.582'de FCEUX bus callback'iyle eşleşiyor. Frame 367'de ROM `$4015=$1F`
ile DMC'yi başlattıktan sonra stepper DMC DMA stall'larını modellemediğinden
sonraki cycle etiketleri geçersiz/eksik; event frame/ID eşleşmesi korunuyor.
Detay: `reference/diagnostics/audio/cold_start_source_cpu_ppu_all_events_20261026.md`.

Ayrı, sessiz ve replay'siz pinned-FCEUX cold run Godot kaynağı/iz girdisi olmadan
4.693 kareyi 0–4692 yürüttü; `--playmov ""`, Lua movie-inactive kontrolleri ve
her karede nötr P1 girişi doğrulandı. İşlem 44.535 seçilmiş CPU olayını, 45.812
APU yazımını ve 105.029 DMC byte çıkışını bellekte toplayıp çıkışta yazdı;
byte değerleri bank `$1E` ROM içeriğiyle eşleşiyor. Bu FCEUX model izi yalnız
davranış/byte doğrulamasıdır; PCM üretmedi ve runtime sentez girdisi değildir.
Start-at-4661 FCEUX varyantı yaklaşık 96 saniye sonra frame/cycle işareti
üretmeden durduruldu; Stop sonrası ses kuyruğu henüz bu yöntemle doğrulanmadı.
Tanı sonuçları `reference/diagnostics/audio/rom_source_scheduler_execution_20261026/`
altında. Üretim WAV, manifest ve Godot runtime değiştirilmedi.

## 2026-10-26 devamı: kalan görüntü, ses ve başlık zamanlaması

En güncel packed-row Godot/FCEUX karşılaştırması 0–4692 arasındaki 4.693
karenin 4.675'inde görünür pikselleri tam eşleştiriyor; kalan 18 karede 45
farklı piksel var. Bunların 27'si FCEUX NewPPU yazılım izinde `$2006` yazısının
iki sprite düzlemi arasındaki paylaşılan `RefreshAddr` değerini değiştirmesiyle
açıklanıyor. Bu, FCEUX modelinin çıktısını açıklar fakat fiziksel 2C02 davranışını
kanıtlamaz. Bağımsız renderer kaynak kodu karşılaştırması da iki sprite düzlemi
okumasını tek yardımcı çağrıda topladığı için bu aralığı donanım açısından
çözmüyor. Frame 3525'in iki pikseli ve diğer 16 piksel için kaynak açıklaması
tamamlanmadı; koordinat veya varsayılan kaydırma yaması yapılmadı. Ayrıntılar
`reference/diagnostics/visual_residual_resolution_gate_20261026.md`,
`reference/diagnostics/opening_residual_pixel_locations_20261026.md` ve
`reference/diagnostics/mesence_fceux_sprite_fetch_model_comparison_20261026.md`
içinde.

Start/başlık denetimi ROM yürütme sırasını frame düzeyinde daralttı: Start
frame 4661'de kabul ediliyor; `$8AF7(A=$17)` arka plan üreticisi frame 4664'te
başlıyor. PPU paleti 4662–4691 boyunca `$0F`, sonra frame 4692'de başlık paleti
ve `$220A=$7F` ilk KICK OFF imlecini kuruyor. Son palette/imleç yazıları vblank'te
scanline 246–251 arasında; `$220A` yazısı line 251 dot 147'de kaydedildi.
Bu, kare kontrol noktalarını destekliyor. Aynı girdili, sessiz FCEUX framebuffer
kıyaslamasında frame 4691 tamamen siyah; frame 4692'de 256×240 ham tamponun ilk
değişimi overscan `(0,0)`/dot 1, görünür 256×224 NTSC kırpımının ilk beyaz başlık
pikseli raw `(117,39)`, PPU line 39/dot 118 olarak ölçüldü. Bu, pinned FCEUX
yazılım framebuffer ölçümüdür; fiziksel PPU çıkış kenarı veya Godot alt-kare
eşliğini kanıtlamaz. Godot/FCEUX endpoint kareleri eşit. Ayrıntı:
`reference/diagnostics/title_handoff_subframe_timing_audit_20261026.md`.

DMC-aware ROM kaynak adımlayıcısının önceki geçici dosyaları workspace
yenilenince kaybolmuştu. Bu sorun artık kısmen giderildi:
`tools/diagnostics/step_rom_source_cpu_ppu_dmc.py` ROM SHA'sını doğrulayıp
FCEUX izi olmadan kare 1109'a kadar kaynak APU/DMC olayları üretiyor. 9.657 APU
yazımı adres/değer/sırasında FCEUX iziyle eşleşti; çevrim farkı −3…0. 20.662
DMC çıktı baytı adres/değer olarak eşleşti; okuma çevrimi farkı −9…+8. Önceki
1043/1046–1049 penceresindeki 222 çevrimlik fark bu nötr-girdi koşusunda
görülmedi. Ayrı aynı-input ROM koşusu Start'ı kare 4661–4667 arasında uygulayıp
frame 4662'ye kadar yürüdü; `$8048` / `$0700=$01` Stop yolu kare 4661'de
FCEUX'in aynı-input PC iziyle doğrulandı. ROM koşusu kare 4660'a kadar 45.432
APU yazımını nötr FCEUX iziyle aynı sırada üretti. Ancak bu kıyas aynı girdi
değil: input timeline kare 697'den itibaren 21 kısa A basışı içeriyor, FCEUX
ses izi ise nötr. Bu nedenle kare 697 sonrası APU çevrim farkları ve kare
1984'teki ilk DMC baytı farkı geçerli bir same-input uyumsuzluk kanıtı değil;
aynı APU/DMC izini almak gerekiyor. Üretim WAV/manifest/runtime değişmedi.
Tam DMC/PCM üretimi için tek sıralı source hook/APU/DMC-bit/DAC olay akışı ve
WaveHi adaptörü hâlâ gerekiyor. Kaynak koşu çıktıları
`reference/diagnostics/audio/rom_only_source_cpu_ppu_dmc_full_start_4662_20261026/`;
şema ve WaveHi eksikleri `reference/diagnostics/audio/wavehi_source_stepper_input_completeness_20261026.md`.

## 2026-10-26 devamı: güncel ROM'suz çalışma kopyası doğrulandı

Güncel Godot kaynaklarından `/tmp/ct2-standalone-audit-20261026-run2` kopyası
kuruldu; `.nes`, `assets/opening/intro/captured/` görüntüleri, emulator capture
klasörleri ve genel `reference/` izleri eklenmedi. Kopyada yalnızca gerekli
ROM'dan çözülmüş `reference/rom_extract/` verileri (273 dosya, 4,4 MiB) ve
belgelenmiş FCEUX RGB paleti vardı. Godot 4.7.2 headless importu ve ana sahnenin
10 karelik açılışı 0 çıkış koduyla tamamlandı. Başlık denetimi kaynak kare
4692'de queue tamamlanmış ve KICK OFF seçili durumla geçti; seçenek onaylanmadı.
Klavye ve oyun kolu Up/Down/Select, Start'ın onaysız kalması, ayrıca ses
yükleme/senkron ve handoff stop/release harness'leri geçti. Bu, bağımsız kaynak
yükleme ve kontrol akışını kanıtlar; gerçek zamanlı tüm-açılış görüntü eşliğini
veya PCM özdeşliğini kanıtlamaz. Tekrar üretim:
`reference/diagnostics/standalone_clean_runtime_20261026.md`.

Sessiz native-window profili Godot 4.7.2 / Apple M2 Pro üzerinde kare 4661'e
77,390 saniyede ulaştı (ortalama 6,928 ms, P95 7,602 ms). 11 host intervali
16,639 ms NTSC bütçesini geçti; en büyükleri başlangıçta 108,151 ms, kare
1046→1047'de 26,961 ms ve kare 3554→3555'te 25,684 ms. 15 kaynak karesi toparlama
adımıyla ilerledi; GPU arka plan yolu etkin ve fallback sayısı sıfırdı. Bu
ortalama akış hızının yaklaşık 60,2 kaynak kare/saniye olduğunu gösterir ama
her karenin zamanında sunulduğunu kanıtlamaz. Ölçüm sessizdi ve ses senkronunu
kontrol etmedi. Tam sonuç:
`reference/diagnostics/opening_runtime_realtime_profile_20261026_latest.md`.

Ses kökeni denetimi üretim WAV'inin hash'inin kendi manifestiyle eşleştiğini,
ancak manifestte belirtilen NSF'nin mevcut olmadığını gösterdi. Depodaki güncel
NSF/build aynı WAV'i üretmiyor; yeni ROM tabanlı aday hash'i
`9c78eec1…` (üretim `325fa794…`). Mevcut builder ayrıca `$0700` RAM izinden
yakalanmış cue karelerini ve kaydedilmiş APU çevrimlerine göre 1.134 çevrimlik
kurulum düzeltmesini kullanıyor. ROM-presenter adayı da henüz aynı müziği
üretmiyor. Bu provenance incelemesinde WAV ve manifest değiştirilmedi; daha sonraki
runtime ses senkronu düzeltmesi WAV/manifesti değiştirmeden ilk `$58` ROM ses
isteğinden döngü karesini öğreniyor. Kaynak NSF/build zinciri ve PCM doğrulaması
çözülmeden müzik birebir/doğrulanmış sayılamaz. Ayrıntı:
`reference/diagnostics/audio/runtime_wav_provenance_audit_20261026.md`.

## 2026-10-26 devamı: aynı girdili ses izi ve görsel artıklar

Nötr FCEUX izi ile A tuşu basışları içeren ROM koşusunu karşılaştırmaktan doğan
frame 1984 `$C2A1=$55` / `$C000=$AA` farkı geçersiz karşılaştırmaydı. Girdi
hash'i eşleşen saklı, sessiz FCEUX iziyle yapılan aynı-girdi kıyasında kare
4660'a kadar 104.106 DMC çıktı baytının adres/değerleri eksiksiz eşleşti; byte
read çevrimi farkı −9…+8, ortalama −0,00187 çevrim. Kare 1984'te iki iz de
`$C2A1=$55` veriyor. Kare 4662'ye kadar 45.452 APU yazımının adres/değer/sırası
eşleşiyor; çevrim farkı −3…+1. Bu, giriş olayları ve DMC örnek byte sırasını
doğruluyor, ancak bit/DAC kenarlarını, WaveHi filtresini veya PCM dalga biçimini
kanıtlamıyor. Rapor:
`reference/diagnostics/audio/rom_only_source_cpu_ppu_dmc_same_input_validation_20261026/README.md`;
tekrarlanabilir kıyaslayıcı `tools/diagnostics/compare_rom_stepper_same_input.py`.

İlk ROM-only WaveHi adayındaki kare 385 / cycle 11.436.326 tampon-faz
çakışması için dar kaynak izi alındı: ROM adımlayıcısı `$C1C8=$AA` DMC
okumasını ve buffer-load'ı aynı çevrimde, önceki `$C1C7=$E9` transferinden
sonra kaydediyor; aynı girdili FCEUX de `$C1C8=$AA` transferini aynı çevrime
etiketliyor. Ayrı 380 karelik kıyasta 7.128 DMC bit-state kancasının sonrası
FCEUX ile durum ve hook zamanı bakımından eşleşiyor; source `edge_cycle`
hook içi tahmindir ve tam açılış DAC olay akışı henüz üretilmedi. Bu kanıt ilk
çakışmanın bayt/adres veya kaynak-okuma çevrimi hatası olmadığını, WaveHi
renderer'ın buffer/bit-clock fazını incelemek gerektiğini gösteriyor; tam
dalga biçimi eşliğini kanıtlamıyor. Tanılama notu:
`reference/diagnostics/audio/rom_only_source_dmc_conflict_window_smoke_390_20261026/README.md`.

Bu ilk çakışma için ROM-kaynak durum düzeltmeli 390-karelik aday da üretildi.
22 bit-edge ve 3 buffer-load satırıyla DMC buffer çakışmaları 1'den 0'a indi;
aday 1.565 ROM DMC baytını tüketti. Düzeltilmiş ve düzeltmesiz source-only
adaylar arasında 286.154 örneğin 4.375'i farklı (korelasyon 0,9999116); bu
yalnızca adaylar arası kıyaslamadır, FCEUX/gerçek NES PCM eşliği değildir. Düzeltme
390. kareyle sınırlı, sonraki 34 çakışmaya uygulanmadı. Rapor:
`reference/diagnostics/audio/rom_stepper_wavehi_source_only_candidate_20261026.md`.

Ardından aynı ROM/input timeline ile stepper 4.662 kareyi yeniden yürüttü;
`--event-cycle-windows` ve `--event-windows-only`, 35 çakışma merkezinin her
çevresindeki 600 çevrimlik bölgeleri seçerek tam, filtresiz olay tablosu yerine
sıkıştırılmış tanı olaylarını sakladı. Dışa aktarılan 2.513 satırın 770'i
`DMC_BIT_EDGE`, 105'i `DMC_BUFFER_LOAD`, 420'si `DMC_DMR_PHASE`, 597'si ses
kancası başla/bitir kayıt çifti ve 24'ü yakın APU yazımıdır. Bu durum olayları
WaveHi adayına uygulanınca 45.452 APU yazımı ve 104.106 ROM DMC baytı işlendi;
ROM bankı `$1E` bayt/adres kontrolleri geçti. Tam 4.662 karelik aday 3.420.912
örnek içeriyor; 35 penceredeki durum düzeltmelerinden sonra tampon-faz
çakışması 0. WAV SHA-256:
`79ce384a3d8847fa84c50ea272f56b898372a9756704841b17f6d13825642a0c`.
Düzeltmeler yalnızca seçili pencerelerde uygulanıyor; geri kalan DMC zamanlaması
per-cycle model ve PCM FCEUX/gerçek NES ile kıyaslanmadı. Bu nedenle ses hâlâ
birebir/doğrulanmış değil; üretim WAV/manifest/runtime değişmedi. Ayrıntılar:
`reference/diagnostics/audio/rom_stepper_wavehi_source_only_candidate_20261026.md`,
`reference/diagnostics/audio/rom_only_source_dmc_conflict_windows_full_4662_20261026/`
ve
`reference/diagnostics/audio/rom_stepper_wavehi_source_state_corrected_full_4662_20261026/candidate_report.json`.

Aynı input timeline ile FCEUX `--soundrecord` yakalaması denemesi sessiz SDL
arka ucunda kare ilerlemeden kilitlendi; WAV oluşmadı ve deneme sonlandırıldı.
Ancak ardından aynı ROM/input timeline hash'ine sahip, daha önce saklanmış
4.693-karelik sessiz FCEUX PCM referansı bulundu; bu nedenle kıyas artık mümkün.
Seçili 35 DMC-buffer çakışma penceresine düzeltme uygulayan 4.662-karelik
aday referansın ilk 3.420.912 örneğinde 0-lag korelasyon 0,988686, RMSE 529,0
ve birebir örnek oranı %16,22 verdi. Ardından ROM kaynak stepper'ı aynı girişle
4692'ye kadar 4.693 frame yürütüldü; cycle end `139730109`. Frame 4662'de dokuz
APU yazısı var, frame 4663–4692 arasında APU yazısı veya DMC okuması yok. Kaynak
frame döngüleriyle üretilen filtre kuyruğu FCEUX'le aynı 3.442.925 örneği verir;
korelasyon 0,988669, RMSE 527,8 ve birebir örnek oranı %16,34. Son 30 kare artık
sentetik uzatma değil; ROM kaynak yürütümündeki APU sessizliği ve gerçek frame
cycle toplamından geliyor. WAV hâlâ FCEUX ile örnek-örnek aynı değil.
Tüm 2.498.684 kaynak DMC bit-edge/buffer durum olayını uygulayan, aynı uzunluktaki
aday korelasyon 0,932165, RMSE 1.745,2 ve birebir örnek oranı %5,96 verdi. Tam
olay akışı PCM'i kötüleştiriyor. FCEUX iç DMC iziyle aynı-cycle alan eşleşmesi
frame 1000 penceresinde 4.109/4.109; frame 4578 civarında 4.432/4.943, frame
500 civarında 1.662/3.091. Eşleşmeyen event-cycle zamanları ve DMC bit/filtre fazı
hala çözülmedi. Her iki sonuç da tanılama adayıdır; üretim
WAV/manifest/runtime değiştirilmedi. Ayrıntılı karşılaştırma:
`reference/diagnostics/audio/rom_stepper_wavehi_full_state_plus_filter_tail_20261026/validation_comparison.json`,
ROM-sonrası ses döngüsü için
`reference/diagnostics/audio/rom_only_source_cpu_ppu_dmc_full_start_4693_20261026/`
ve
`reference/diagnostics/audio/rom_stepper_wavehi_sparse_state_rom_frame4692_20261026/`.

Godot ses denetleyicisi, manifestteki yakalanmış cue kareleri yerine ROM sunucudan
gelen ilk `$58` ses isteğini döngü başlangıcı olarak alıyor ve sonraki `$58`
isteklerinde yeniden eşleniyor. Güncellenen harness; sinyal gelmeden önce
başlangıç karesinin boş olduğunu, `$58` ile kurulduğunu ve stop/serbest bırakma
akışını doğruladı. Temiz ROM'suz kopyada ses harness'i ve kare 4692 başlık geçişi
yeniden geçti. WAV ve manifest aynı kaldı; bu değişiklik PCM eşliğini kanıtlamıyor.

Packed-row tam açılış kıyasında görünür alandaki 4.693 karenin 4.675'i tam
eşleşiyor; kalan 18 karede 45 piksel var. Son aynı-koşu pinned FCEUX NewPPU
izinde 45/45 artık pikselin tamamı CPU `$A175/$A178` raster handler'ındaki
`STY $2006` / `STA $2006` yazımlarına bağlandı: ikinci yazım her durumda sprite
plane-1 fetch dot'uyla aynı anda ve ilk yazımdan 4 CPU çevrimi sonra gerçekleşiyor.
Bu, FCEUX'in ortak `RefreshAddr` davranışını kaynak-kod ve canlı bus/CHR iziyle
açıklar; gerçek 2C02 donanım davranışı olduğunu kanıtlamaz. Godot'ta ilgili
scanline sprite fetch ve IRQ giriş fazı yürütülmediğinden kaynak-zamanlı runtime
modeli hâlâ eklenmedi; piksel/koordinat yaması yok. Ayrıntılar:
`reference/diagnostics/opening_visual_residual_source_attribution_20261026.md`,
`reference/diagnostics/untraced_residual_oam_chr_audit_20261026.md` ve
`reference/diagnostics/oam_all_residual_trace_20261026/`.

**Hazır olma durumu:** ROM ve emülatör olmadan açılış, ROM'dan üretilen yeni müzik,
başlık geçişi ve iki seçenekli klavye/kol imleci temiz kopyada doğrulandı.
Görünür ekran tüm 4.693 karede FCEUX ile aynı; CE6 değişiklikleri 301/301 karede
ayrıca sınandı. Hedef hâlâ tamamlanmadı: altı A160 event zaman farkı, WAV'daki
PCM farkı ve intro sunucusunun bazı kare-içi komut/Start geçiş ankrajları açık.
Fiziksel NES renk kenarı değil, pinned FCEUX emulator-model çıktısı ölçülüyor.
Kalan büyük iş ses örnek eşliği ve üç yerel PPU/IRQ faz karesidir; güvenilir
bitiş tarihi henüz verilemiyor. “Birebir” iddiası yok.

## 2026-10-26 önceki runtime sesi ve açılış doğrulaması (CE6 öncesi)

> Tarihsel not: bu bölüm CE6 WAV ve A160 çizelgesi varsayılana alınmadan önceki üretimi anlatır. Aşağıdaki güncel durum ve `AGENTS.md` içindeki son doğrulama özeti geçerlidir.


Aynı-input FCEUX PCM referansıyla karşılaştırılan ROM-stepper/WaveHi adayı,
mevcut runtime WAV'inin yerini aldı; önceki WAV ve manifest
`reference/diagnostics/audio/legacy_runtime_audio_20261026/` içine korundu.
Yeni aktif WAV SHA-256 `61ab9583b57494d713602059c1cc8adef1bd4236d4fa3528d6fc408e395f51c7`,
3.442.925 örnek/44,1 kHz ve ROM kaynak frame 4692'ye kadar yürütülmüş olaylardan
üretildi. Aynı-input FCEUX WAV'i aynı uzunlukta; korelasyon 0,988669, RMSE 527,8,
örneklerin %16,34'ü tam eşit. FCEUX PCM yalnız doğrulama için kullanıldı. Üretim
manifesti artık ROM hash'ini, stepper/renderer kaynaklarını, input hash'ini ve
bilinen farkları kaydediyor; WAV birebir değil.

Tam DMC bit-edge akışını ROM stepper'ından `edge_cycle` zamanlarıyla kullanan
yeni offline aday aynı-input PCM korelasyonunu yalnızca `0,988669` → `0,988730`
yükseltti; RMSE `527,76` → `526,02`, tam örnek oranı `%16,3417` → `%16,3440`.
Kaynak DMC adres/değer sırası FCEUX ile 104.106/104.106 eşleşiyor. Yeni pinned
FCEUX timer-edge trace'i `edge_cycle`'ı doğrudan 7.076/7.076 kez frame 367–380'de
ve 99.820/99.820 kez frame 4481–4661'de doğruladı; geç bölümde 19.765 hook
snapshot'ında yalnız accumulator değeri ayrışırken timer kenarı aynı kaldı.
Buna rağmen geç döngü WAV korelasyonu `0,8696–0,8788`; tam-edge adayının genel
PCM artışı çok küçük. Aday tanılama amaçlı bırakıldı, runtime WAV ve manifest
değişmedi; çözülecek esas ses farkı filtre/mixer/örnek fazı. İz ve kıyas:
`reference/diagnostics/audio/fceux_dmc_timer_edge_validation_20261026/` ve
`reference/diagnostics/audio/dmc_inner_edge_replay_audit_20261026.md`.

ROM yürütümü frame 4663–4692 arasında APU yazımı veya DMC okuması üretmiyor;
gerçek kaynak frame-cycle'larıyla filtre kuyruğu aynı örnek uzunluğunu veriyor.
`opening_source_runtime.gd` artık Start ile 30-frame siyah geçiş başladığında
ses akışını kesmiyor; ROM-kaynaklı kuyruk title reveal sırasında devam ediyor.
Güncel temiz kopya `/tmp/ct2-standalone-audit-20261026-run4/` içinde ROM,
emulator ve capture dosyaları olmadan Godot 4.7.2 importu, 10-frame ana sahne,
ses cue sync, title handoff sırasında çalma, frame-4692 title endpoint'i ve
klavye/oyun kolu imleç denetimleri geçti. KICK OFF seçili kaldı; hiçbir seçenek
onaylanmadı. Adımlar ve sınırlar:
`reference/diagnostics/standalone_clean_runtime_20261026.md`.

Görsel tarafta FCEUX NewPPU aynı-run izi 45/45 artık pikseli ortak
`RefreshAddr` davranışıyla ROM `$A175/$A178` yazımlarına bağladı. ROM-only
predictor 36/36 store için scanline, CPU cycle ve değeri eşledi, fakat dot'ta
0/36 exact; fark 3–9 PPU dot. Bilinen 18 kare/üç satırla sınırlanan statik
chunk POC 36/36 dot üretti, ancak capture penceresine bağlı olduğundan held-out
kanıt değil. ROM branch koşuluyla genelleştirme denemesi frame 26'da hedef
olayları kaybetti: gate 869.461 satırda etkinleşti ve 0/36 store tahmini verdi.
En küçük sonraki iz, slot-2 hook'tan `$A178` store'una kadar her `runppu(x)`
sınırında PPU line/dot, x, CPU timestamp/debt/PC, MMC3 count/reload/enable,
PPUCTRL/MASK ve sprite-slot değerlerini soğuk başlangıçtan kaydetmek, sonra
ayrı bir withheld aralıkta sınamaktır. Pinned FCEUX kaynağı sprite-fetch/MMC3
çevresindeki 1–2-dot `runppu()` sınırlarında CPU talimatlarının çalıştığını
gösteriyor; resetten MMC3 IRQ, scroll/latch, sprite-slot, vblank ve odd-frame
çağrılarını birlikte yürüten genel model hâlâ yok. Bu yüzden Godot'a capture-dot
tablosu veya koordinat yaması eklenmedi; 45 piksel ve alt-kare parity açık.
Ayrıntı ve başarısız/genel olmayan POC'ler:
`reference/diagnostics/a160_fceux_subframe_timing_blocker_20261026.md`.
Başlık için FCEUX'in ilk görünür NTSC-crop pikseli frame
4692 line 39/dot 118 ölçüldü; bu Godot'un alt-kare eşliğini veya fiziksel 2C02
çıkışını kanıtlamıyor. İzler:
`reference/diagnostics/oam_all_residual_trace_20261026/README.md`,
`reference/diagnostics/a160_rom_only_dot_prediction_20261026/prediction_report.json`
ve `reference/diagnostics/title_first_pixel_trace_20261026/README.md`.

**Durum:** Godot açılış→başlık akışı bağımsız çalışıyor; `KICK OFF` seçili,
seçenekler onaylanmıyor. Bu paragrafın 4.675 karelik ölçümü daha sonraki
`opening_runtime_full_20261026_shared_sprite_fetch` tam yakalamasıyla
geçersiz kılındı: ROM-stepper `$2006` plane-1 okuma düzeltmesi Godot çizicisine
eklendi ve aynı girdili 0–4692 tekrarında görünür 256×224 alanın 4.693/4.693
karelerinin tamamı FCEUX ile piksel piksel eşleşti (yalnız belgelenmiş açılış
OSD maskesi uygulanarak). Ham 256×240 alandaki 142 fark, 2369–2377 karelerinin
yalnızca y=0 overscan satırında; görünür oyunda fark yok. Bu sonuç FCEUX NewPPU
modeliyle görsel parity'dir, fiziksel 2C02 alt-kare/renk kenarı eşliği değildir.
Tam rapor ve metrik: `reference/diagnostics/opening_runtime_full_20261026_shared_sprite_fetch/README.md`
ve `osd_masked_summary.json`. Yürütme/harness kare kare karşılaştırma içindir;
tek başına canlı oynatımın kesintisiz 60.0988 Hz olduğunu kanıtlamaz.

Müzik ROM verisinden üretilmiş mevcut WAV ile çalıyor ama tam PCM eşleşmesi
yok. Geç bölümde ham üçgen kanalının faz/zamanlayıcı farkı kanıtlandı. En yeni
line-47/48 çağrı izlerinde `runppu()` bölünmesi FCEUX ile aynı, ancak CPU PC ve
çevrim kredisi line-47 girişinde zaten farklı; line-46 sonundaki ilk ayrışma
henüz bulunmadı. Üretim WAV'i kaynaklı bir düzeltme ölçülene kadar değişmiyor.
Güncel sessiz native pencere profili 4.661 kaynak karesini 77,313 saniyede
oynattı (~60,29 kare/sn); 11.142 host aralığının 10'u 16,639 ms bütçeyi aştı,
en uzunu 43,130 ms. Ortalama hedefe yakın, seyrek kısa takılmalar sürüyor.

### 2026-10-26 follow-up

FCEUX NewPPU source instrumentation now captures `runppu()` boundaries,
slot-2 MMC3 hooks, and `$2006` stores around the 18 residual frames. The same
input trace matches 36/36 ROM `$A175/$A178` stores by frame, scanline, dot,
value, and post-store PC; all 18 low-byte stores fall inside an `x=2` call.
This explains the pinned FCEUX callback sample point but does not establish
physical 2C02 timing. A diagnostic ROM-only stepper now mirrors FCEUX's
interrupt-only return update (`_PI = _P`) and predicts the target 36 writes
with exact scanline/dot/value and zero CPU-cycle error. A same-run validation
of 196 writes across 98 frames also matches after mapping FCEUX `framectr` to
input/movie `source_frame` with the measured +3 offset. This is diagnostic
FCEUX-model parity; no Godot renderer or production audio asset changed. See
`reference/diagnostics/a160_fceux_subframe_trace_20261026/irq_return_phase_prediction_report.json`
and the trace README. The planned shared-address sprite-plane path is at
`reference/diagnostics/oam_all_residual_trace_20261026/godot_sprite_fetch_integration_plan_20261026.md`;
it still needs to be implemented and checked against the current 4,675 exact
visible frames.

Late-loop raw-channel attribution now covers 5,390,271 cycles in source frames
4481–4661. With FCEUX's recorded 255/256 channel gain applied, pulse 1, pulse 2,
noise, and DMC match exactly on every cycle. Triangle is the remaining raw
channel mismatch (26,427 exact cycles / 0.4903%, correlation 0.73665); mixed
raw WaveHi correlation is 0.87278. The mismatch begins before mixing/filtering,
so the remaining audio gap is triangle phase/state/timer behavior. Runtime WAV,
manifest, renderer, and assets remain unchanged. See
`reference/diagnostics/audio/wavehi_late_loop_channel_attribution_20261026.md`.

### 2026-10-26 güncel görsel tam-yakalama düzeltmesi

Yukarıdaki eski 4.675/4.693 durum metni geçersiz kılınmıştır. `rom_ppu_nametable_screen_renderer.gd`
ROM-stepper'ın kaynaklı `$A175/$A178` olaylarından sprite plane-1 okumasındaki
tam nametable adresini çözüp ROM plane-0 ile birleştiriyor. Aynı girdili tam
Godot/FCEUX karşılaştırması 4.693 görünür karenin tümünde 100% RGB eşleşmesi
verdi; önceki 18 karedeki 45 piksel de eşleşiyor. Ham 256×240 çıktıda kalan
142 fark yalnızca y=0 overscan'da ve FCEUX'in görünür 224 satırına girmiyor.
FCEUX emulator-model parity doğrulandı; fiziksel 2C02 rengi/alt-kare çıkışı,
canlı hız dalgalanması ve ses örnek eşliği bu görüntü ölçümüyle doğrulanmış
sayılmaz. Kaynak: `reference/diagnostics/opening_runtime_full_20261026_shared_sprite_fetch/README.md`
ve `osd_masked_summary.json`.

### 2026-10-26 frame-380 ses zamanlaması izi

Frame 380'de line 48'in ilk PC/credit farkı görüldü; bunu line 47'nin sonunda
da izledik (310 `runppu()` çağrısı aynı boyutlarda). Daha sonra line 0'dan
line 48'e kadar yapılan geniş aynı-girdi karşılaştırması ilk ayrışmayı line 39,
post-dot 91'e taşıdı. Her iki model aynı `$8A07` PC, çevrim ve krediyle ROM
`$CE` (`DEC absolute`) komutunu yürütüyor; Py65 1.2.0 bu komuta 3 çevrim,
pinned FCEUX CycTable 6 çevrim veriyor. Üç çevrimlik fark sonraki PC/kredi
kaymasını başlatıyor; satır-47/48 `runppu()` bölünmesi kök neden değil.
Tanılama adayı `$CE=6` ile line0→48 arasındaki 14.833 sınır durumunun tümünü,
381 frame çevrimini, 1.196 APU yazımını ve 3.788 DMC okuma fazını/947 byte'ı
FCEUX ile tam eşleştirdi; önceki DMC okuma çevrimi artığı −4…+6 idi. Aday WAV
aynı uzunluktaki ilk 381 frame PCM penceresinde r=0,98673 verdi; üretim WAV'in
aynı örnek aralığı r=0,99725. DMC'siz pencere az farkla iyileşirken frame
367–381 DMC penceresi 0,99677'den 0,91750'ye düştü. Kaynak CPU zamanlaması
düzeldi. Matched-index ablation, bu korelasyon düşüşünün `$CE` düzeltmesinden
değil, ilk DMC örneğinde devreye giren 34.593 hook-cycle DMC-state kaydından
geldiğini gösterdi: CE6 adayı bu state enjeksiyonu olmadan frame 381'e kadar
dağıtılan WAV ile byte-byte aynı. Hook-cycle DMC state'i henüz WaveHi sentez
girdisi olarak doğrulanmış değil; aday ve üretim WAV/manifest değiştirilmedi.
Rapor:
`reference/diagnostics/audio/rom_stepper_opcode_ce6_candidate_20261026/source_timing_validation.json`
ve `wavehi_candidate/fceux_validation_comparison.json`. Geniş iz:
`reference/diagnostics/audio/rom_stepper_source380_to_line48_trace_20261026/earliest_divergence_summary.json`;
önceki sınır raporu:
`reference/diagnostics/audio/instruction_resume_boundary_candidate_20261026.md`.

Line-47'de aday `$9FE2` sıçramasını FCEUX'ten önce tamamlıyordu; geniş iz bunun
line 39'daki `$CE` çevrim tablosu farkının devamı olduğunu gösterdi ve aday
düzeltme line48/dot280 IRQ checkpoint'ine kadar CPU state'ini eşleştirdi.
Üretim WAV'inde değişiklik yok.

Tam `$CE=6` ROM-source replay'i frame 4692'ye dek 4.692 frame çevrim
sınırlarının tümünü, 45.452 APU yazımının adres/değer/çevrimini ve 104.106 DMC
byte'ının adres/değerini eşleştirdi; DMC cycle etiketlerinde 104.105 tam, bir
byte +3 CPU çevrim. Ancak bu adımlayıcıdan yeniden üretilen A160 `$A175/$A178`
olay tablosu eski tabloya göre 301 frame / 602 yazımı değiştiriyor. Her iki
tabloyu retained FCEUX bus izine karşılaştırmak ve sonra etkilenmiş karelerde
Godot görüntü parity'sini doğrulamak gerekiyor; runtime PPU timeline henüz
değiştirilmedi. Ayrıntı: `reference/diagnostics/audio/rom_stepper_opcode_ce6_full_4692_20261026/`.

Yanlış PCM düşüşünün kaynağı `$CE=6` değil: ilk DMC'den itibaren enjekte edilen
34.593 instruction-hook DMC state snapshot'ı rendererin çevrim tabanlı iç
fazını bozuyor. ROM-source `edge_cycle` DAC-transition adayı (7.540 kenar,
frame 367–381) aynı 279.550 örnek prefix'inde üretim WAV'iyle r=0,9999999996,
sıfır lag, nRMSE 0,000027 ve %99,978 örnek eşitliği verdi; bu aday üretim
WAV'inin tamamını byte-byte yeniden üretmiyor ve FCEUX ile ölçülen WAV parity'sini
artırmıyor. Ayrı per-cycle yeniden üretim denetimi dağıtılan dosyayı byte-byte
kurabildi; bu yalnızca build'in tekrarlanabilirliğini doğruluyor, sesin FCEUX ile
eşitliğini değil. Bu nedenle üretim sesi/manifest aynı kaldı; DMC'nin ROM'dan
türeyen çevrim içi faz modeli ve full-opening PCM eşliği hâlâ açık.
Kıyas ve kaynak: `reference/diagnostics/audio/rom_stepper_opcode_ce6_candidate_20261026/runtime_alignment_edge_cycle_dac.json`
ve `instruction_resume_boundary_candidate_20261026.md`.

### 2026-10-26 Stop-sonrası ses kuyruğu denetimi

ROM runtime WAV'i frame 4692'ye kadar sürer; FCEUX'e göre frame 4661–4692
aralığında correlation 0,66013 (22.722 örnek, RMSE 450,98). Kuyruk uzunluğu
eksik değil; FCEUX sesi yaklaşık 4679'a kadar duyulur. Kaynak ve FCEUX Stop
yazımları değer/sıra bakımından eşleşiyor. Üçgen kanalı Stop'tan önce zaten
farklı: cycle 138.806.913'te ROM-source step 8/timer 255, FCEUX step 12/timer
293. Geç döngüde pulse 1/2, noise ve DMC katkıları çevrim bazında eşleşirken
üçgen yalnız %0,49 eşleşiyor. Bu iz instruction-hook frame-update adayı içindir;
aynı Stop/kuyruk aralığında aday çıktı ile dağıtılan WAV byte-byte aynıdır, yani
üçgen farkı runtime dosyasına da taşınır. Yeni tanılama klonu dağıtılan WAV'i
byte-byte tekrar üretti ve ROM-only üretim rendererinin beş fazında kanal,
WaveHi, FIR ve SexyFilter checkpoint'leri çıkardı; production WAV/manifest
değişmedi. Frame 4661'de `mrindex/mrratio` FCEUX ile eşit, ancak FIR geçmişindeki
1.025 örneğin 0'ı eşleşiyor (MAE 807,88). Üçgen fazı aynı noktada zaten ayrık
olduğundan filtre farkının bağımsız katkısı henüz ayrıştırılmış değil; frame
4692 için native FCEUX filtre-state kaydı yok. WAV'in son 30 karesi Stop sonrası
tutulmuş durumun 29.780 CPU çevrimlik periyotla tekrarlanmasıyla üretilmiş; bu
uzunluğu tamamlıyor ama ROM tarafından ayrı yürütülmüş zamanlama değil. Kaynak
renderer frame 4692'de 139.730.093 CPU çevriminde duruyor; FCEUX doğrulama ucu
16 çevrim ileride. İlk CPU-cycle farkının kaynağı line 39'daki `$CE` çevrim
hesabı olarak bulundu ve 6 çevrimli tanılama adayı deneniyor. Runtime WAV ve
manifest değişmedi. Tam denetim:
`reference/diagnostics/audio/rom_source_only_post_stop_tail_audit_20261026/README.md`;
state replay:
`reference/diagnostics/audio/rom_source_only_post_stop_tail_audit_20261026/source_render_checkpoint/README.md`.
Kanıtlar `reference/diagnostics/audio/rom_stepper_wavehi_frame_update_events_rom_frame4692_20261026/triangle_state_comparison.json`,
`reference/diagnostics/audio/rom_stepper_wavehi_channel_raw_4481_4661_20261026/channel_wavehi_comparison_fceux_volumes.json`
ve `reference/diagnostics/audio/fceux_filter_state_checkpoint_20261025/`.

### 2026-10-26 reset başlangıç ankrajı Godot'a aktarıldı

`tools/diagnostics/trace_rom_only_cold_start_reset.py` reset vektöründen source
frame 9'a kadar oynatımı tekrar üretir; ROM CPU/PPU olayları oluşturulurken
FCEUX kaydı kullanılmaz. İki ayrı sessiz FCEUX reset iziyle 31.834/31.834
PC/çevrim satırı, A/X/Y/SP, gerçek `N,V,D,I,Z,C` bayrakları, RAM snapshot'ları
ve 9/9 frame-cycle satırı eşleşiyor. Ham `$P` register farkları yalnız Py65 ve
FCEUX'in canlı olmayan B/U gösterim bitleri `$10/$20`; CSV'de ham değerler
korunuyor. ROM-only PPU RAM ilk kez frame 9 sonunda `$3F00–$3F1F` aralığının
tümünü `$0F` yapıyor; kare içindeki palette yazım çevrimi ölçülmüş değil.

Bu kaynak olayları `assets/opening/rom_logic/cold_start_bootstrap_phase.json`
olarak Godot projesine alındı. Presenter artık slot `$0005`'i `_ready()` içinde
kurmuyor; ROM-kaynaklı frame 8 olayında kurup ilk hazır taramayı, NMI serbest
bırakmasını ve siyah palette frame'ini aynı kaynaktan alıyor. Focused Godot
startup verifier geçti; `.nes` ve emulator capture içermeyen izole kopyada da
startup verifier ve frame-4692 onaysız title handoff geçti. `GOAL` test çıktısı
ve kaynağı `reference/diagnostics/rom_only_cold_start_stepper_20261026/README.md`.
Bu, ilk reset/startup **kare ankrajını** kaldırır; Godot hâlâ frame-kare
ilerliyor, CPU-cycle/subframe yürütümü değil. EC/F1/FD/F8 capture ankrajları ve
ses doğruluğu açık.


## 2026-10-26 son uygulanan CE6 kaynakları ve temiz-kopya denetimi

Varsayılan A160 timeline artık doğrulanmış `$CE=6` ROM-stepper olaylarını kullanıyor;
eski timeline `reference/diagnostics/audio/rom_stepper_opcode_ce6_full_4692_20261026/a160_visual_events_baseline_pre_ce6.json`
içinde korundu. Tam tablo FCEUX bus'ıyla 7.264 olayda kıyaslandı: 7.258 çevrim,
7.258 scanline, 7.260 dot ve bütün 7.264 değer eşleşiyor. Kalan altı yazım
frames 1029/1760/2121'de; bu üç yerel geçiş için IRQ/PPU faz izi araştırılıyor.
Değişen 301 karenin görünür görüntüsü 301/301 eşit; 50 ham fark yalnız y=0
aşım satırında. Üretim timeline'ı için başlık geçişi de yeniden denetlendi.

Aynı `$CE=6` ROM kaynaklarından üretilen daha yakın ses WAV'ı runtime'a alındı.
Yeni SHA-256 `8891669e579d24cb34f950f717023b77f13131377e1870dabd9325998575cf8f`;
önceki WAV/manifest geri dönüş kopyası
`reference/diagnostics/audio/runtime_audio_pre_ce6_wavehi_20261026/` altında.
FCEUX WAV'ıyla korelasyon 0,98867'den 0,99604'e yükseldi, RMSE 527,76'dan 327,08'e
düştü; tam örnek eşitliği %16,43 olduğu için WAV sample-exact değil. Cue sync ve
Start sonrası ses kuyruğu testi yeni WAV ile geçti.

Güncel runtime kopyası `/tmp/ct2-standalone-ce6/` yalnız Godot sahneleri/scripts,
ROM-derived proje kaynakları ve gerekli FCEUX RGB paletini içeriyor; `.nes`,
emülatör ve capture klasörleri yok. Godot 4.7.2 importu, frame-4692 unconfirmed
title handoff, KICK OFF/CONTINUE klavye/gamepad seçimleri ve ses cue/handoff
kontrolleri geçti. Kısa CPU/PPU ankrajları ve audio PCM farkı hâlâ açık; bu
hedefin tamamlandığı veya birebir olduğu anlamına gelmiyor.

## 2026-10-27 Kare-içi zamanlama takibi

### Etkin kapanış hedefi

Bu takip için etkin Codex hedefi: Start yoklamasının iki büyük ROM-only çevrim
sapmasını çözmek, başlık raster anını ROM-kaynaklı sanal saatle temsil etmenin
doğru ve standalone bir yolunu belirlemek, sonra aynı girişte CPU-kare-piksel
eşliğini doğrulamak. FCEUX çevrim/piksel izleri yalnızca sonradan doğrulama
referansıdır; Godot runtime'a yakalama zamanlaması kopyalanmayacak. Fiziksel
2A03/2C02 silikon eşliği gerçek konsol kaydı olmadan iddia edilmeyecek.

- [x] Frame 3598 ve 3601 yoklama kalıntılarının kaynaklı nedeni bulundu:
  adımlayıcı IRQ kabulünden sonra kredi erken dönüşünde `prev_p` durumunu
  eşitlemiyordu ve aynı MMC3 IRQ'yu tekrar kabul ediyordu. ROM-only adımlayıcıda
  tanılama düzeltmesi yapıldı ve 4.653 yoklamanın tamamı yeniden ölçüldü.
- [x] Frame 4692 ilk pikselinin ROM/PPU durumundan sanal raster zamanını türet;
  bunun Godot masaüstü taramasını denetlemediğini doğrulayarak doğrulama saati
  olarak tut.
- [x] Değişiklikten sonra açılış ve title endpoint aynı-girdi doğrulamasını çalıştır;
  `KICK OFF` seçimini koru ve hiçbir seçeneği onaylama.
- [x] Fiziksel konsol ölçümü yoksa sınırı ve gerekli ölçüm düzenini belgede açık
  tut; fiziksel zamanlama için tahminî bir runtime değeri üretme.

ROM-only adımlayıcı, aynı ROM/input rotasında 4.653 `$802C` Start yoklamasının
kare-içi çevrimlerini üretti; FCEUX zamanları yalnızca sonradan doğrulamada
kullanıldı. IRQ maskesi düzeltmesinden sonra 3.680/4.653 yoklama tam eşleşiyor,
4.649/4.653 ise ±3 CPU çevrim içinde; en büyük artık 7 çevrim. Frame 3598 ve
3601 artık tam eşleşiyor. Frame 4661'deki hedef Start yoklaması da tam eşleşiyor
(offset 4.288, mutlak 138.781.421). Bu yalnızca tanılama adımlayıcısındaki
kaynak yürütme düzeltmesidir; Godot runtime'a yakalama zamanı aktarılmadı.
Kalan dört karede göreli offset farkları −7/−6/+5/+4; bunların mutlak yoklama
farkı −3/−3/+3/+3 çevrim ve kare başlangıçlarının 1–4 çevrim kaymasıyla
açıklanıyor. Tüm 4.653 yoklamanın mutlak zamanı 4.652 karede ±3 çevrim içinde,
frame 473'te en büyük fark 7 çevrim. Yeni bir kaynaklı kod düzeltmesi için kanıt
yok; ölçümler `reference/diagnostics/start_poll_rom_source_timing_20261027/irq_mask_corrected_full_audit/remaining_poll_residual_audit.md` içinde.
Fiziksel NES zamanlaması ve adımlayıcının DMA/PPU sınırlamaları açık kalıyor.

Godot'un kaydedilmiş frame 4691'i 61.440/61.440 siyah RGB pikseli içeriyor;
frame 4692'deki ilk görünür nonblack piksel `(117,39)`, beyaz ve FCEUX'ün
`line 39/dot 118` konumuyla aynı. Pinned FCEUX NewPPU zaman izi, bu koordinatı
frame-4692 başlangıcından 6.858 CPU çevrimi sonrasına (mutlak çevrim
139.707.186) yerleştiriyor; satır birleştirici pikseli 32/48 CPU çevrimi sonra
yazıyor. Bu FCEUX-model beam zamanıdır, Godot ekran taraması veya fiziksel
2C02 çıkış ölçümü değildir. Fiziksel NES doğrulaması için senkron girişli gerçek
konsol saat/video yakalaması gerekiyor. Hiçbir Godot runtime zamanlama kodu bu
denetimde değiştirilmedi. Ayrıntılar:
`reference/diagnostics/timing_gap_followup_20261027.md`,
`reference/diagnostics/physical_console_timing_capture_protocol_20261027.md`,
`reference/diagnostics/start_poll_rom_source_timing_20261027/`.

ROM-only doğrulayıcı frame-4691 son CPU/PPU fazından (`cpu_credit=-64`, −4 PPU
noktası), ROM kaynaklı başlık görüntüsündeki ilk beyaz pikselden `(117,39)` ve
NTSC satır geometrisinden frame 4692 için `139.707.186` sanal çevrimini türetiyor;
bağımsız FCEUX NewPPU koordinat zamanı da aynı çevrim. IRQ maskesi düzeltmesinden
sonra başlık aktarım olayları yeniden üretildi: 330 olayın sırası/çevrimleri ve
`$8048` ankrajı değişmedi; sanal raster doğrulayıcısı tekrar PASS verdi. Godot
bunu alt-karede ekrana basmıyor; bütün dokuyu kare olarak sunduğu için bu değeri
runtime zamanlamasına bağlamak doğru değil. Doğrulayıcı ve ayrıntılı hesap:
`tools/diagnostics/verify_source_only_title_virtual_raster.gd` ve
`reference/diagnostics/source_only_title_virtual_raster_20261027.md`.

Güncellenmiş ROM-only kaynak olay tablosunun 330 başlık olayı, sırası/çevrim
offsetleri ve `$8048` başlangıç ankrajı önceki tabloyla aynı. Düzeltilmiş
adımlayıcıdan yeniden üretildikten sonra sanal raster doğrulayıcısı Godot 4.7.2'de
tekrar PASS verdi. Ana sahne title handoff denetimi de geçti: `KICK OFF`
görünüyor, geçiş çalışmıyor ve seçenek onaylanmıyor. Fiziksel konsol ölçüm
protokolü ve donanım yokluğu
`reference/diagnostics/physical_console_timing_capture_protocol_20261027.md` içinde.

Ana sahne doğrulama komutu:

```sh
godot --headless --audio-driver Dummy --path . --script tools/diagnostics/verify_main_opening_title_handoff.gd
```

## 2026-10-27 açılış dilimi kapanışı

Yazılım dilimi tamamlandı: soğuk açılış ROM komutlarından yürütülüyor; Start
ROM-derived `$802C` poll zamanında örnekleniyor; handoff kuyruğu source-clock
olaylarını tüketiyor; frame 4692'de `KICK OFF` seçili, `CONTINUE` görünür ve iki
seçenek de onaysız kalıyor. Başlık kuyruğunun son paketi cycle 920030'da,
başlığın ilk ROM pikselleri için kaynak-model eşiği cycle 925729'da. Aynı ana
sahne doğrulayıcısı menüyü bu eşiğin öncesinde gizli ve sonrasında görünür buldu.

Godot 4.7.2 temiz import, başlık handoff, klavye/oyun kolu yön-seçim kontrolleri,
ses başlangıç/loop/handoff kuyruğu ve sahne kapanışı ROM'suz temiz kopyada geçti.
Önceki tam aynı-girdili görsel denetim 4.693/4.693 görünür 256×224 kareyi
FCEUX'le eşleştiriyor; WAV doğrulaması FCEUX referansının 3.442.925 örneğinin
tamamında byte eşitliği gösteriyor. ROM, emulator, yakalanmış ekran veya
yakalanmış WAV runtime için gerekmiyor; oyuna eklenen ses ROM verisinden
üretilmiş proje WAV kaynağıdır.

Kalan sınır artık yazılım diliminin açılış akışını bitirmesini engellemiyor:
Godot masaüstü monitörünün gerçek tarama fazını NES CPU/PPU çevrimine kilitlemez;
fiziksel 2A03/2C02 sinyali de konsol ölçümü olmadan doğrulanamaz. Kaynak ROM
stepper'ı ve pinned-FCEUX raster modeli yazılım doğrulamasını sağlar. Canlı
profildə açılış 77,302 saniyede frame 4661'e ulaştı; nadir host/OS takılmaları
ara karelerin masaüstünde atlanmasına yol açabilir. Bu fiziksel alt-kare eşliği
ve her ekranda kesintisiz sunum iddiası değildir.

Bu görev title ekranında durur; seçenek onayı veya sonraki oyun akışı bu dilime
dahil değildir. Yeni bir oyun bölümüne geçiş için sonraki hedef ayrı belirlenir.
