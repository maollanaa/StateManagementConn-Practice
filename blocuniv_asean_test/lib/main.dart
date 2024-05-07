import 'package:flutter/material.dart';
import 'dart:convert'; // Library untuk bekerja dengan JSON
import 'package:http/http.dart' as http; // Library untuk melakukan HTTP request
import 'package:flutter_bloc/flutter_bloc.dart'; // Library untuk state management menggunakan BLoC pattern

// Model untuk menyimpan data universitas
class University {
  final String name; // Nama universitas
  final String? stateProvince; // Negara bagian atau provinsi (opsional)
  final List<String> domains; // Daftar domain web universitas
  final List<String> webPages; // Daftar halaman web universitas
  final String alphaTwoCode; // Kode negara 2 huruf
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
      name: json['name'],
      stateProvince: json['state-province'], // Data ini bisa null
      domains: List<String>.from(json['domains']), // Konversi daftar dari JSON
      webPages: List<String>.from(json['web_pages']), // Sama seperti di atas
      alphaTwoCode: json['alpha_two_code'], // Kode dua huruf negara
      country: json['country'], // Nama negara
    );
  }
}

// Abstraksi untuk Event BLoC
abstract class UniversityEvent {}

// Event untuk mengambil data universitas berdasarkan negara
class FetchUniversitiesEvent extends UniversityEvent {
  final String country; // Negara yang menjadi parameter untuk fetch data
  FetchUniversitiesEvent(this.country); // Konstruktor
}

// BLoC untuk mengelola state daftar universitas
class UniversityBloc extends Bloc<UniversityEvent, List<University>> {
  UniversityBloc() : super([]) { // Inisialisasi state dengan daftar kosong
    on<FetchUniversitiesEvent>(_fetchUniversities); // Mendefinisikan handler untuk event FetchUniversitiesEvent
  }

  // Handler untuk event FetchUniversitiesEvent
  Future<void> _fetchUniversities(
    FetchUniversitiesEvent event,
    Emitter<List<University>> emit,
  ) async {
    try {
      // Mengambil data universitas dari API
      final universities = await _fetchUniversitiesFromApi(event.country);
      emit(universities); // Emit daftar universitas yang berhasil diambil
    } catch (e) {
      print('Error: $e'); // Log error jika terjadi
      emit([]); // Emit daftar kosong jika gagal
    }
  }

  // Fungsi untuk mengambil data universitas dari API berdasarkan negara
  Future<List<University>> _fetchUniversitiesFromApi(String country) async {
    final response = await http.get(
        Uri.parse('http://universities.hipolabs.com/search?country=$country'));

    if (response.statusCode == 200) { // Jika berhasil
      final List<dynamic> data = jsonDecode(response.body); // Parsing data JSON
      return data.map((json) => University.fromJson(json)).toList(); // Konversi ke daftar University
    } else {
      throw Exception('Failed to load universities'); // Lempar exception jika gagal
    }
  }
}

void main() {
  runApp(MyApp()); // Memulai aplikasi Flutter
}

// Widget utama aplikasi
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BlocProvider(
        create: (context) => UniversityBloc(), // Inisialisasi BLoC
        child: UniversitiesPage(), // Tampilkan halaman utama
      ),
    );
  }
}

// Widget untuk halaman utama yang menampilkan daftar universitas
class UniversitiesPage extends StatefulWidget {
  @override
  _UniversitiesPageState createState() => _UniversitiesPageState(); // Membuat state untuk widget ini
}

// State untuk widget halaman universitas
class _UniversitiesPageState extends State<UniversitiesPage> {
  final List<String> _aseanCountries = [
    'Indonesia',
    'Singapore',
    'Malaysia',
    'Thailand',
    'Philippines',
    'Vietnam',
    'Myanmar',
    'Cambodia',
    'Brunei',
    'Laos',
  ]; // Daftar negara ASEAN

  String _selectedCountry = 'Indonesia'; // Negara yang dipilih awalnya

  // Inisialisasi state dan fetch data universitas berdasarkan negara yang dipilih
  @override
  void initState() {
    super.initState();
    context.read<UniversityBloc>().add(FetchUniversitiesEvent(_selectedCountry)); // Tambahkan event fetch data universitas
  }

  // Fungsi untuk membangun tampilan widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ASEAN Universities'), // Judul di AppBar
      ),
      body: Column(
        children: [
          Padding( // Beri padding pada dropdown
            padding: const EdgeInsets.all(16.0),
            child: DropdownButton<String>(
              value: _selectedCountry, // Negara yang dipilih
              onChanged: (String? newValue) { // Ketika dropdown berubah
                setState(() { // Update state
                  _selectedCountry = newValue!;
                  context
                      .read<UniversityBloc>() // Akses BLoC
                      .add(FetchUniversitiesEvent(newValue)); // Tambahkan event untuk fetch data baru
                });
              },
              items: _aseanCountries.map<DropdownMenuItem<String>>((String value) { // Buat daftar item dropdown
                return DropdownMenuItem<String>(
                  value: value, // Nilai item dropdown
                  child: Text(value), // Teks untuk item dropdown
                );
              }).toList(),
            ),
          ),
          // Menggunakan BlocBuilder untuk mendengarkan perubahan state di UniversityBloc
          BlocBuilder<UniversityBloc, List<University>>(
            builder: (context, universities) { 
              // Jika daftar universitas kosong, tampilkan indikator loading
              if (universities.isEmpty) {
                return CircularProgressIndicator(); // Indikator loading
              }
              return Expanded( // Gunakan Expanded agar ListView bisa mengambil ruang penuh
                child: ListView.builder( // Membuat ListView untuk menampilkan daftar universitas
                  itemCount: universities.length, // Jumlah item di dalam ListView
                  itemBuilder: (context, index) { // Bagaimana setiap item dibuat
                    final university = universities[index]; // Universitas pada indeks saat ini
                    return Padding( // Beri padding pada setiap item
                      padding: const EdgeInsets.all(8.0),
                      child: Card( // Gunakan Card untuk setiap item
                        child: Padding( // Beri padding dalam Card
                          padding: const EdgeInsets.all(16.0),
                          child: Column( // Menggunakan Column untuk mengatur tampilan data universitas
                            crossAxisAlignment: CrossAxisAlignment.start, // Align ke kiri
                            children: [
                              Text(
                                university.name, // Nama universitas
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold, // Font tebal untuk nama
                                ),
                              ),
                              SizedBox(height: 8.0), // Spasi antar elemen
                              Row( // Gunakan Row untuk menampilkan beberapa informasi dalam satu baris
                                children: [
                                  Text('State/Province: '), // Label
                                  Text(university.stateProvince ?? 'N/A'), // Tampilkan 'N/A' jika stateProvince null
                                ],
                              ),
                              Row(
                                children: [
                                  Text('Domains: '), // Label
                                  Text(university.domains.join(', ')), // Tampilkan semua domain, dipisahkan koma
                                ],
                              ),
                              Row(
                                children: [
                                  Text('Web Pages: '), // Label
                                  Text(university.webPages.join(', ')), // Tampilkan semua halaman web, dipisahkan koma
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
                                  Text(university.country), // Nama negara
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
