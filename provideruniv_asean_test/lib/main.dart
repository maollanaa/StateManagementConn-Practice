import 'package:flutter/material.dart';
import 'dart:convert'; // Library untuk bekerja dengan data JSON
import 'package:http/http.dart' as http; // Library untuk melakukan HTTP request
import 'package:provider/provider.dart'; // Library untuk state management dengan Provider

// Model untuk menyimpan data universitas
class University {
  final String name; // Nama universitas
  final String? stateProvince; // Negara bagian atau provinsi (bisa null)
  final List<String> domains; // Daftar domain universitas
  final List<String> webPages; // Daftar halaman web universitas
  final String alphaTwoCode; // Kode negara dua huruf
  final String country; // Nama negara

  // Konstruktor untuk membuat objek University
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
      name: json['name'], // Ambil nama dari JSON
      stateProvince: json['state-province'], // Ambil stateProvince (bisa null)
      domains: List<String>.from(json['domains']), // Konversi ke daftar domain
      webPages: List<String>.from(json['web_pages']), // Konversi ke daftar halaman web
      alphaTwoCode: json['alpha_two_code'], // Kode negara dua huruf
      country: json['country'], // Nama negara
    );
  }
}

// Provider untuk mengelola state universitas
class UniversityProvider extends ChangeNotifier { // Menggunakan ChangeNotifier
  List<University> _universities = []; // Daftar universitas
  String _selectedCountry = 'Indonesia'; // Negara yang dipilih (default Indonesia)

  // Getter untuk daftar universitas
  List<University> get universities => _universities;

  // Getter untuk negara yang dipilih
  String get selectedCountry => _selectedCountry;

  // Mengubah negara yang dipilih dan meng-update data universitas
  void setSelectedCountry(String country) {
    _selectedCountry = country; // Ubah negara yang dipilih
    fetchUniversities(); // Panggil fungsi untuk fetch data universitas
    notifyListeners(); // Panggil notifyListeners untuk memberi tahu pengamat
  }

  // Fungsi untuk mengambil data universitas dari API berdasarkan negara yang dipilih
  Future<void> fetchUniversities() async {
    final response = await http.get(
        Uri.parse(
            'http://universities.hipolabs.com/search?country=$_selectedCountry')); // URL dengan negara yang dipilih

    // Jika response statusnya 200 (berhasil), parse data JSON dan set daftar universitas
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body); // Parsing JSON
      _universities = data.map((json) => University.fromJson(json)).toList(); // Konversi ke daftar University
    } else {
      throw Exception('Failed to load universities'); // Lempar exception jika gagal
    }
  }
}

void main() {
  runApp(
    ChangeNotifierProvider( // Menggunakan Provider untuk state management
      create: (context) => UniversityProvider(), // Membuat instance dari UniversityProvider
      child: MyApp(), // Jalankan aplikasi
    ),
  );
}

// Widget utama aplikasi
class MyApp extends StatelessWidget {
  final List<String> aseanCountries = [
    'Indonesia',
    'Singapura',
    'Malaysia',
    'Thailand',
    'Brunei Darussalam',
    'Filipina',
    'Vietnam',
    'Kamboja',
    'Laos',
    'Myanmar'
  ]; // Daftar negara ASEAN

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold( // Menggunakan Scaffold sebagai kerangka halaman utama
        appBar: AppBar(
          title: Text('Universities'), // Judul di AppBar
        ),
        body: Column( // Menggunakan Column untuk mengatur layout
          children: [
            Padding( // Tambahkan padding pada dropdown
              padding: const EdgeInsets.all(8.0),
              child: DropdownButton<String>(
                // Dropdown untuk memilih negara
                value: context.watch<UniversityProvider>().selectedCountry, // Ambil negara yang dipilih dari provider
                onChanged: (value) { // Ketika dropdown berubah
                  context.read<UniversityProvider>().setSelectedCountry(value!); // Ubah negara yang dipilih dan fetch data universitas
                },
                items: aseanCountries.map((country) { // Buat daftar item dropdown dari daftar negara ASEAN
                  return DropdownMenuItem<String>(
                    value: country, // Nilai dropdown
                    child: Text(country), // Teks yang ditampilkan di dropdown
                  );
                }).toList(),
              ),
            ),
            Expanded( // Gunakan Expanded agar ListView bisa mengambil sisa ruang
              child: Consumer<UniversityProvider>( // Gunakan Consumer untuk mendengarkan perubahan di UniversityProvider
                builder: (context, provider, child) { // Builder untuk membangun ListView
                  return ListView.builder( // Membuat ListView untuk menampilkan daftar universitas
                    itemCount: provider.universities.length, // Jumlah item di ListView
                    itemBuilder: (context, index) { // Bagaimana setiap item dibuat
                      final university = provider.universities[index]; // Universitas pada indeks saat ini
                      return Padding( // Tambahkan padding pada setiap item
                        padding: const EdgeInsets.all(8.0),
                        child: Card( // Gunakan Card untuk setiap item
                          child: Padding( // Tambahkan padding dalam Card
                            padding: const EdgeInsets.all(16.0),
                            child: Column( // Gunakan Column untuk mengatur tampilan data universitas
                              crossAxisAlignment: CrossAxisAlignment.start, // Posisi rata kiri
                              children: [
                                Text( // Tampilkan nama universitas
                                  university.name,
                                  style: TextStyle(
                                    fontSize: 18.0, // Ukuran font
                                    fontWeight: FontWeight.bold, // Gaya font tebal
                                  ),
                                ),
                                SizedBox(height: 8.0), // Ruang antar elemen
                                Row( // Gunakan Row untuk menampilkan beberapa informasi dalam satu baris
                                  children: [
                                    Text('State/Province: '), // Label
                                    Text(university.stateProvince ?? 'N/A'), // Tampilkan 'N/A' jika stateProvince null
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text('Domains: '), // Label
                                    Text(university.domains.join(', ')), // Daftar domain, dipisahkan dengan koma
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text('Web Pages: '), // Label
                                    Text(university.webPages.join(', ')), // Daftar halaman web, dipisahkan dengan koma
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text('Alpha Two Code: '), // Label
                                    Text(university.alphaTwoCode), // Kode dua huruf negara
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text('Country: '), // Label
                                    Text(university.country), // Nama negara
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
      ),
    );
  }
}
