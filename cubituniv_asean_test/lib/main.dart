import 'package:flutter/material.dart';
import 'dart:convert'; // Library untuk mengolah data JSON
import 'package:http/http.dart' as http; // Library untuk melakukan request HTTP
import 'package:flutter_bloc/flutter_bloc.dart'; // Library untuk state management

// Model untuk menyimpan data universitas
class University {
  final String name; // Nama universitas
  final String? stateProvince; // Negara bagian atau provinsi (opsional)
  final List<String> domains; // Daftar domain web universitas
  final List<String> webPages; // Daftar halaman web universitas
  final String alphaTwoCode; // Kode negara 2 huruf
  final String country; // Nama negara

  // Constructor untuk membuat objek University
  University({
    required this.name,
    this.stateProvince,
    required this.domains,
    required this.webPages,
    required this.alphaTwoCode,
    required this.country,
  });

  // Factory method untuk membuat objek University dari data JSON
  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      name: json['name'],
      stateProvince: json['state-province'],
      domains: List<String>.from(json['domains']),
      webPages: List<String>.from(json['web_pages']),
      alphaTwoCode: json['alpha_two_code'],
      country: json['country'],
    );
  }
}

// Cubit untuk mengelola state daftar universitas
class UniversitiesCubit extends Cubit<List<University>> {
  UniversitiesCubit() : super([]); // Inisialisasi dengan daftar kosong

  // Metode untuk mengambil data universitas dari API berdasarkan nama negara
  Future<void> fetchUniversities(String country) async {
    final response = await http.get(
        Uri.parse('http://universities.hipolabs.com/search?country=$country'));

    // Jika response statusnya 200 (berhasil), parse data JSON menjadi daftar universitas
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      emit(data.map((json) => University.fromJson(json)).toList());
    } else {
      // Jika gagal, lempar exception
      throw Exception('Failed to load universities');
    }
  }
}

void main() {
  runApp(MyApp()); // Jalankan aplikasi Flutter
}

// Widget utama aplikasi
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BlocProvider(
        create: (context) => UniversitiesCubit(), // Inisialisasi Cubit
        child: HomePage(), // Tampilkan halaman utama
      ),
    );
  }
}

// Halaman utama aplikasi
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState(); // Buat state untuk halaman utama
}

// State untuk halaman utama
class _HomePageState extends State<HomePage> {
  final List<String> _aseanCountries = [
    'Indonesia',
    'Singapore',
    'Malaysia',
    'Thailand',
    'Philippines',
    'Vietnam',
    'Myanmar',
    'Cambodia',
    'Laos',
    'Brunei'
  ]; // Daftar negara ASEAN
  String _selectedCountry = 'Indonesia'; // Negara yang dipilih (default Indonesia)

  // Saat inisialisasi, langsung fetch data universitas berdasarkan negara yang dipilih
  @override
  void initState() {
    super.initState();
    context.read<UniversitiesCubit>().fetchUniversities(_selectedCountry);
  }

  // Fungsi untuk membangun widget halaman utama
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ASEAN Universities'), // Judul di AppBar
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0), // Padding untuk elemen di dalam kolom
            child: DropdownButton<String>(
              value: _selectedCountry, // Negara yang dipilih saat ini
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCountry = newValue!;
                  context
                      .read<UniversitiesCubit>()
                      .fetchUniversities(_selectedCountry); // Fetch data universitas berdasarkan negara baru yang dipilih
                });
              },
              items: _aseanCountries
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value, // Nilai yang diwakili oleh Dropdown
                  child: Text(value), // Tampilan teks dalam Dropdown
                );
              }).toList(), // Buat daftar item untuk Dropdown dari daftar negara ASEAN
            ),
          ),
          Expanded( // Expanded agar ListView bisa mengambil ruang penuh
            child: BlocBuilder<UniversitiesCubit, List<University>>(
              builder: (context, universities) {
                return ListView.builder(
                  itemCount: universities.length, // Jumlah item dalam ListView
                  itemBuilder: (context, index) { // Cara membuat setiap item
                    final university = universities[index]; // Universitas pada indeks saat ini
                    return Padding(
                      padding: const EdgeInsets.all(8.0), // Padding untuk setiap item
                      child: Card( // Gunakan Card untuk setiap item
                        child: Padding(
                          padding: const EdgeInsets.all(16.0), // Padding dalam Card
                          child: Column( // Kolom untuk mengatur tampilan informasi universitas
                            crossAxisAlignment: CrossAxisAlignment.start, // Penyelarasan ke kiri
                            children: [
                              Text(
                                university.name, // Teks nama universitas
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold, // Tambahkan tebal untuk nama
                                ),
                              ),
                              SizedBox(height: 8.0), // Ruang antar elemen
                              Row( // Gunakan Row untuk menampilkan beberapa informasi dalam satu baris
                                children: [
                                  Text('State/Province: '), // Label
                                  Text(university.stateProvince ?? 'N/A'), // Nilai (gunakan 'N/A' jika null)
                                ],
                              ),
                              Row(
                                children: [
                                  Text('Domains: '), // Label
                                  Text(university.domains.join(', ')), // Tampilkan semua domain yang dipisahkan koma
                                ],
                              ),
                              Row(
                                children: [
                                  Text('Web Pages: '), // Label
                                  Text(university.webPages.join(', ')), // Tampilkan semua halaman web yang dipisahkan koma
                                ],
                              ),
                              Row(
                                children: [
                                  Text('Alpha Two Code: '), // Label
                                  Text(university.alphaTwoCode), // Tampilkan kode dua huruf
                                ],
                              ),
                              Row(
                                children: [
                                  Text('Country: '), // Label
                                  Text(university.country), // Tampilkan nama negara
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
