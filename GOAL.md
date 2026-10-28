# Etkin hedef: KICK OFF'tan ilk maç komut ekranına

**Durum: ACTIVE — tamamlanmadı.** Bu dosya güncel hedefi, kısa durum özetini ve
bitiş ölçütlerini tutar. Ayrıntılı tarihçe ve ölçüm kayıtları `reference/`
altındaki raporlardadır; önceki uzun GOAL kaydı
[`goal_progress_history_20261028.md`](reference/goal_progress_history_20261028.md)
olarak korunmuştur.

## Hedef ve kapsam

Godot 4'te, başlık ekranında seçili `KICK OFF` seçeneğinden başlayıp ilk maçın
komut menüsüne ulaşan bağımsız bir dilim tamamla. Menü ilk açıldığında hiçbir
futbol aksiyonu seçili olmasın. `CONTINUE` akışına girme ve futbol aksiyonunu
onaylama.

Çalışma zamanı ROM veya emülatör istememeli. Görseller, metin, ses ve davranış
sağlanan ROM baytlarından ve çözümlenmiş oyun mantığından türetilmeli; emülatör
görüntüleri ve kaydedilmiş WAV'ler yalnızca gözlem/karşılaştırma içindir.

## Masaüstü dağıtım kapsamı

Windows, Linux ve macOS sürümleri için About ve güncelleme akışı korunmalı.
Otomatik kontrol güncelleme indirmemeli; indirme/kurulum için açık kullanıcı
seçimi ve hedef yazılabilirliği gerekir. Her platformda doğru paket türü
kullanılmalı; sürüm paketleri üçüncü taraf bildirimleri ile SHA-256/Sigstore
manifestlerini içermeli. Masaüstü menüleri 256×224 oyun görüntüsünü veya oyun
akışını bozmamalı. Ayrıntılar Godot skill'inin masaüstü/release referansında ve
`.github/workflows/` altındadır; bu kapsam ilk-maç milestone'unun uç noktasını
değiştirmez.

## Mevcut durum — 28 Ekim 2026

- Soğuk açılıştan başlık menüsüne önceki dilim tamamlandı. 2026-10-27 tarihli
tam aynı-girdi yazılım ölçümü 4.693/4.693 görünür kareyi ve 3.442.925 ses
  örneğini eşleşmiş raporladı. Bu Godot/FCEUX yazılım karşılaştırmasıdır; fiziksel
  NES tarama veya silikon zamanlaması iddiası değildir.
- Taze `KICK OFF` rotasının çeşitli ROM-byte yürütücüleri ve izleri var; ancak
  bunlar üretim rotasını baştan sona çalıştıran canlı görev/olay zincirine henüz
  bağlanmadı. Mevcut standalone denetim ilk komut menüsünün üretim rotasında
  kurulduğunu kanıtlamıyor.
- İlk menüye giden canlı oyuncu/receiver durumu, görev devamı, saha aktörleri ve
  menü kurulumu hâlâ açık. Aynı-girdi rota görseli, zamanlaması ve sesi için
  tamamlanmış eşlik doğrulaması yok.
- Bir sonraki kaynak geçişi ve kabul ölçütleri [`PLANS.md`](PLANS.md) içindeki
  **Current work package** bölümünde. Her yeni bulgu, ilgili kaynak raporuna
  yazılmalı; bu özet yalnız durum değişince güncellenmeli.

## Bitiş ölçütleri

- Olağan kullanıcı girdisiyle ROM-kaynaklı rota ilk komut menüsüne ulaşır; test
  için RAM enjekte edilmez ve çözümlenmemiş geçişler kare gecikmeleriyle taklit
  edilmez.
- İlk menüde hiçbir aksiyon seçili değildir; gözlenen klavye/oyun kolu
  seçimi doğru çalışır. `CONTINUE` veya bir futbol aksiyonu açılmaz.
- Aynı başlangıç ve girdilerle görünür çıktı, menü seçimi, kaynak olay sırası,
  zamanlama ve ses karşılaştırılır; kalan farklar açıkça yazılır.
- Temiz Godot kopyası, ROM ve FCEUX olmadan aynı uç noktaya ulaşır.

## Etkin kanıtlar

- Kaynak görev/bootstrap ve NMI: [`first_command_root_task_bootstrap_and_nmi_20261028.md`](reference/rom_extract/gameplay/first_command_root_task_bootstrap_and_nmi_20261028.md), [`first_command_task_boundary_trace_20261028.md`](reference/rom_extract/gameplay/first_command_task_boundary_trace_20261028.md)
- `$C515/$CB0F` devamı ve üretim rotası sınırı: [`first_command_callback_scheduler_trace_20261028.md`](reference/rom_extract/gameplay/first_command_callback_scheduler_trace_20261028.md), [`first_command_live_route_composition_boundary_20261028.md`](reference/rom_extract/gameplay/first_command_live_route_composition_boundary_20261028.md)
- Saha ve ilk menü görsel farkları: [`kickoff_field_intro_visual_gap_20261028.md`](reference/rom_extract/gameplay/kickoff_field_intro_visual_gap_20261028.md), [`first_menu_visible_output_comparison_boundary_20261028.md`](reference/rom_extract/gameplay/first_menu_visible_output_comparison_boundary_20261028.md)
- Rota sesi: [`first_match_audio_source.md`](reference/rom_extract/gameplay/first_match_audio_source.md), [`route_cue55_asset_onset_audit_20261027.md`](reference/diagnostics/audio/route_cue55_asset_onset_audit_20261027.md)
- Önceki açılış ses üretimi/karşılaştırması: [`opening_audio_build_and_pcm_validation_20261027.md`](reference/rom_extract/audio/opening_audio_build_and_pcm_validation_20261027.md)
- Dış araştırma kaynakları ve sınırları: [`online_reverse_engineering_resources.md`](reference/rom_extract/intro/online_reverse_engineering_resources.md)

Çalışma kuralları için `AGENTS.md`; iş sırası için `PLANS.md` kullan. Bu dosyadaki
durum özeti ile ayrıntılı raporlar çelişirse, yeni kanıta göre durumu ve ilgili
raporu güncelle; eski tarihli arşiv kaydını güncel gerçek olarak kullanma.
