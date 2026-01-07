import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../data/setting.dart';
import '../data/tamu.dart';
import '../service/export_service.dart';
import '../service/hive_service.dart';
import '../service/import_service.dart';
import '../component/custom_header.dart';
import '../component/custom_footer.dart';
import '../component/nav_drawer.dart' as Custom;
import '../service/setting_service.dart';

class GuestBookPage extends StatefulWidget {
  const GuestBookPage({super.key});

  @override
  State<GuestBookPage> createState() => _GuestBookPageState();
}

class _GuestBookPageState extends State<GuestBookPage> {
  final Map<int, String> monthNames = {
    1: 'Januari', 2: 'Februari', 3: 'Maret', 4: 'April',
    5: 'Mei', 6: 'Juni', 7: 'Juli', 8: 'Agustus',
    9: 'September', 10: 'Oktober', 11: 'November', 12: 'Desember',
  };

  String? _activeSearchColumn;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  late DateTime _tanggalMulai;
  late DateTime _tanggalAkhir;

  final List<String>_keperluanList = [
    "Survey",
    "Konsultasi",
    "Lainnya",
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _tanggalMulai = now.subtract(const Duration(days: 30));
    _tanggalAkhir = now;
  }

  Future<void> _deleteTamuAndAntrian(dynamic tamuKey, int tamuId) async {
    await HiveService.deleteTamu(tamuKey);

    final antrianBox = HiveService.getAntrianBox();
    try {
      final antrianKey = antrianBox.keys.firstWhere(
            (key) {
          final tamuDiAntrian = antrianBox.get(key);
          return tamuDiAntrian?.tamuId == tamuId;
        },
      );
      if (antrianKey != null) {
        await HiveService.deleteAntrian(antrianKey);
        debugPrint("✅ Antrian dengan tamuId $tamuId berhasil dihapus.");
      } else {
        debugPrint("ℹ️ Tidak ada antrian dengan tamuId $tamuId.");
      }
    } catch (e) {
      debugPrint("Info: Tamu dengan ID $tamuId tidak ditemukan di antrian untuk dihapus.");
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showEditDialog(dynamic tamuKey, Tamu tamu) async {

    String? initialSelectedKeperluan;
    String initialKeperluanLainnya = '';

    if (_keperluanList.contains(tamu.keperluan)) {
      initialSelectedKeperluan = tamu.keperluan;
      initialKeperluanLainnya = '';
    } else {
      initialSelectedKeperluan = 'Lainnya';
      initialKeperluanLainnya = tamu.keperluan;
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return _EditGuestDialog(
          tamuKey: tamuKey,
          tamu: tamu,
          initialSelectedKeperluan: initialSelectedKeperluan,
          initialKeperluanLainnya: initialKeperluanLainnya,
          keperluanList: _keperluanList,
          nama: tamu.nama,
          instansi: tamu.instansi,
        );
      },
    );
  }

  Widget _buildRangeFilterButton(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Kolom 1: Tanggal Mulai
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    "Mulai: ${DateFormat('dd MMM yyyy', 'id_ID').format(_tanggalMulai)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  onPressed: () => _selectTanggalMulai(context),
                ),
              ),
              const SizedBox(width: 8),

              // Kolom 2: Tanggal Akhir
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    "Akhir: ${DateFormat('dd MMM yyyy', 'id_ID').format(_tanggalAkhir)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  onPressed: () => _selectTanggalAkhir(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectTanggalMulai(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalMulai,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('id', 'ID'),
    );

    if (picked != null && picked != _tanggalMulai) {
      if (picked.isAfter(_tanggalAkhir)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tanggal Mulai tidak boleh setelah Tanggal Akhir')),
          );
        }
        return;
      }
      setState(() {
        _tanggalMulai = picked;
      });
    }
  }

  Future<void> _selectTanggalAkhir(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalAkhir,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('id', 'ID'),
    );

    if (picked != null && picked != _tanggalAkhir) {
      if (picked.isBefore(_tanggalMulai)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tanggal Akhir tidak boleh sebelum Tanggal Mulai')),
          );
        }
        return;
      }
      setState(() {
        _tanggalAkhir = picked;
      });
    }
  }

  Widget _buildDataTable(List<Tamu> tamuList) {
    final tamuBox = HiveService.getTamuBox();

    DataColumn _buildSearchableColumn(String label, String columnName) {
      final isActive = _activeSearchColumn == columnName;

      return DataColumn(
        label: InkWell(
          onTap: () {
            setState(() {
              if (_activeSearchColumn == columnName) {
                // Jika kolom yang sama diklik, nonaktifkan pencarian
                _activeSearchColumn = null;
                _searchText = '';
                _searchController.clear();
              } else {
                // Aktifkan pencarian di kolom baru
                _activeSearchColumn = columnName;
                _searchText = '';
                _searchController.clear();
              }
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.blue : Colors.black,
                ),
              ),
              if (isActive)
                SizedBox(
                  width: 150, // Sesuaikan lebar TextField
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Cari $label...',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchText = value;
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Tentukan Columns
    final columns = [
      const DataColumn(label: Text("No")),
      _buildSearchableColumn("ID",'id'),
      _buildSearchableColumn("Tanggal", 'tanggal'),
      _buildSearchableColumn("Nama", 'nama'),
      _buildSearchableColumn("Keperluan", 'keperluan'),
      _buildSearchableColumn("Instansi", 'instansi'),
      const DataColumn(label: Text("Aksi")),
    ];

    // Tentukan Rows: Jika list kosong, rows adalah [], menghasilkan hanya header.
    List<DataRow> rows = [];

    if (tamuList.isNotEmpty) {
      rows = List.generate(tamuList.length, (index) {
        final tamu = tamuList[index];

        final key = tamuBox.keys.firstWhere(
                (k) => tamuBox.get(k)?.id == tamu.id,
            orElse: () => null
        );

        final arrivalDateText = DateFormat('dd MMM yyyy', 'id_ID').format(tamu.arrivalTime);

        return DataRow(
          cells: [
            DataCell(Text("${index + 1}")),
            DataCell(Text(tamu.id.toString())),
            DataCell(Text(arrivalDateText)),
            DataCell(Text(tamu.nama)),
            DataCell(Text(tamu.keperluan)),
            DataCell(Text(tamu.instansi)),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tombol EDIT
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: (key != null) ? () {
                      _showEditDialog(key, tamu);
                    } : null,
                  ),
                  // Tombol HAPUS dengan Konfirmasi
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: (key != null)
                        ? () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Konfirmasi Hapus"),
                          content: Text("Apakah Anda yakin ingin menghapus data tamu dengan ID ${tamu.id} (${tamu.nama})?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text("Batal"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text("Hapus", style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        _deleteTamuAndAntrian(key, tamu.id);
                      }
                    }: null,
                  ),
                ],
              ),
            ),
          ],
        );
      });
    }

    return DataTable(
      headingRowColor: WidgetStateProperty.all(Colors.grey[300]),
      columns: columns,
      rows: rows, // Jika tamuList kosong, rows adalah [], menghasilkan tabel dengan hanya header
    );
  }

  Widget _buildDeleteAllButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.delete_forever),
        label: const Text("Hapus Semua Data"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Konfirmasi Hapus Semua Data"),
              content: const Text("⚠️ **PERINGATAN!** Apakah Anda yakin ingin menghapus **semua** data tamu? Aksi ini tidak dapat dibatalkan."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("Batal"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text("Hapus Semua", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await HiveService.clearAll();
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Semua data tamu berhasil dihapus!')),
            );
          }
        },
      ),
    );
  }

  Widget _buildExportButton(List<Tamu> tamuList, BuildContext context) {
    if (tamuList.isEmpty) return const SizedBox.shrink();

    final String labelRentang = "${DateFormat('dd MMM').format(_tanggalMulai)} - ${DateFormat('dd MMM yyyy').format(_tanggalAkhir)}";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.download, color: Colors.green),
        label: Text("Export $labelRentang (${tamuList.length} data)"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        onPressed: () async {
          try {
            await ExportService.exportTamuToExcel(
              tamuList,
              _tanggalMulai.month, // Digunakan sebagai parameter default file name
              _tanggalMulai.year,  // Digunakan sebagai parameter default file name
              _tanggalMulai,
              _tanggalAkhir,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ Data berhasil dieksport!')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('❌ Gagal mengeksport: $e')),
            );
          }
        },
      ),
    );
  }

  Widget _buildImportButton(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.upload_file, color: Colors.blue),
      label: const Text("Import Data"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      onPressed: () async {
        try {
          await ImportService.importTamuFromFile();

          if (mounted) {
            setState(() {}); // Refresh tampilan setelah import
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Data berhasil diimpor!')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Gagal mengimpor data: $e')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tentukan batas waktu yang tepat untuk filter
    final DateTime filterStart = _tanggalMulai.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    final DateTime filterEnd = _tanggalAkhir.copyWith(hour: 23, minute: 59, second: 59, millisecond: 999, microsecond: 999);

    return Scaffold(
      drawer: const Custom.NavigationDrawer(),
      body: Column(
        children: [
          const CustomHeader(),
          _buildRangeFilterButton(context),

          Expanded(
            child: ValueListenableBuilder(
              valueListenable: HiveService.getTamuBox().listenable(),
              builder: (context, Box<Tamu> box, _) {
                final allTamu = box.values.toList();

                // Filter berdasarkan Rentang Tanggal
                List<Tamu> filteredByDate = allTamu.where((t) =>
                t.arrivalTime.isAfter(filterStart.subtract(const Duration(milliseconds: 1))) &&
                    t.arrivalTime.isBefore(filterEnd.add(const Duration(milliseconds: 1)))
                ).toList();

                // Filter berdasarkan Pencarian Teks (jika aktif)
                List<Tamu> filtered = filteredByDate;
                if (_searchText.isNotEmpty && _activeSearchColumn != null) {
                  final query = _searchText.toLowerCase();
                  filtered = filteredByDate.where((t) {
                    String valueToSearch = '';

                    // kolom pencarian
                    switch (_activeSearchColumn) {
                      case 'id':
                        valueToSearch = t.id.toString();
                        break;
                      case 'tanggal':
                        valueToSearch = DateFormat('dd MMM yyyy', 'id_ID').format(t.arrivalTime);
                        break;
                      case 'nama':
                        valueToSearch = t.nama;
                        break;
                      case 'keperluan':
                        valueToSearch = t.keperluan;
                        break;
                      case 'instansi':
                        valueToSearch = t.instansi;
                        break;
                    }

                    return valueToSearch.toLowerCase().contains(query);
                  }).toList();
                }

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildImportButton(context),
                        const SizedBox(width: 8),
                        // Export hanya tampilkan tombol jika ada data
                        if (filtered.isNotEmpty) _buildExportButton(filtered, context),
                      ],
                    ),

                    // 🌟 MODIFIKASI FINAL: Hanya menampilkan _buildDataTable di dalam SingleChildScrollView
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        // Jika filtered kosong, DataTable hanya akan menampilkan header
                        child: _buildDataTable(filtered),
                      ),
                    ),

                    _buildDeleteAllButton(context),
                  ],
                );
              },
            ),
          ),
          ValueListenableBuilder<Box<Setting>>(
            valueListenable: SettingService.settingListenable,
            builder: (context, box, child) {
              final setting = box.get('appSetting');
              final tampilkanFooter = setting?.tampilkanCustomFooter ?? true;

              if (tampilkanFooter) {
                return const CustomFooter();
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// WIDGET BARU: _EditGuestDialog (Memperbaiki refresh state dropdown/textfield)
// ----------------------------------------------------------------------

class _EditGuestDialog extends StatefulWidget {
  final dynamic tamuKey;
  final Tamu tamu;
  final String? initialSelectedKeperluan;
  final String initialKeperluanLainnya;
  final List<String> keperluanList;
  final String nama;
  final String instansi;

  const _EditGuestDialog({
    required this.tamuKey,
    required this.tamu,
    required this.initialSelectedKeperluan,
    required this.initialKeperluanLainnya,
    required this.keperluanList,
    required this.nama,
    required this.instansi,
  });

  @override
  __EditGuestDialogState createState() => __EditGuestDialogState();
}

class __EditGuestDialogState extends State<_EditGuestDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _nama;
  late String _instansi;
  late String? _selectedKeperluan;
  late TextEditingController _keperluanLainnyaController;

  @override
  void initState() {
    super.initState();
    _nama = widget.nama;
    _instansi = widget.instansi;
    _selectedKeperluan = widget.initialSelectedKeperluan;
    _keperluanLainnyaController = TextEditingController(text: widget.initialKeperluanLainnya);

    _keperluanLainnyaController.selection = TextSelection.fromPosition(
        TextPosition(offset: _keperluanLainnyaController.text.length));
  }

  @override
  void dispose() {
    _keperluanLainnyaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("📝 Edit Data Tamu"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                initialValue: widget.tamu.id.toString(),
                decoration: const InputDecoration(
                  labelText: 'ID Tamu',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _nama,
                decoration: const InputDecoration(labelText: 'Nama', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Nama tidak boleh kosong' : null,
                onSaved: (value) => _nama = value!,
              ),
              const SizedBox(height: 16),

              // Menu Dropdown
              DropdownButtonFormField<String>(
                value: _selectedKeperluan,
                decoration: const InputDecoration(labelText: 'Keperluan', border: OutlineInputBorder()),
                items: widget.keperluanList.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedKeperluan = value;
                    if (value != "Lainnya") {
                      _keperluanLainnyaController.clear();
                    }
                  });
                },
                validator: (value) => value == null ? 'Keperluan tidak boleh kosong' : null,
              ),

              if (_selectedKeperluan == "Lainnya") ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _keperluanLainnyaController,
                  enabled: _selectedKeperluan == "Lainnya",
                  decoration: const InputDecoration(
                    labelText: 'Tuliskan Keperluan',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_selectedKeperluan == 'Lainnya' && (value == null || value.isEmpty)) {
                      return 'Keperluan tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 16),
              TextFormField(
                initialValue: _instansi,
                decoration: const InputDecoration(labelText: 'Instansi', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Instansi tidak boleh kosong' : null,
                onSaved: (value) => _instansi = value!,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Batal"),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();

              String finalKeperluan;

              if (_selectedKeperluan == 'Lainnya') {
                finalKeperluan = _keperluanLainnyaController.text;
              } else {
                finalKeperluan = _selectedKeperluan ?? "";
              }

              if (finalKeperluan.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Keperluan harus diisi.')),
                );
                return;
              }

              final updatedTamu = HiveService.getTamuBox().get(widget.tamuKey) as Tamu;

              updatedTamu.nama = _nama;
              updatedTamu.keperluan = finalKeperluan;
              updatedTamu.instansi = _instansi;

              await updatedTamu.save();

              if (mounted) {
                Navigator.pop(context); // Tutup dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Data tamu berhasil diperbarui!')),
                );
              }
            }
          },
          child: const Text("Simpan"),
        ),
      ],
    );
  }
}