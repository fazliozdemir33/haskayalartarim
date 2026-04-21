import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart' hide ImageSource;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';

// Theme Management
class ThemeManager extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

final ThemeManager themeManager = ThemeManager();

String getAuthErrorMessage(String code) {
  switch (code) {
    case 'user-not-found':
      return 'Bu e-posta adresi ile kayıtlı bir kullanıcı bulunamadı.';
    case 'wrong-password':
      return 'Girdiğiniz şifre hatalı.';
    case 'invalid-email':
      return 'Lütfen geçerli bir e-posta adresi giriniz.';
    case 'email-already-in-use':
      return 'Bu e-posta adresi zaten kullanımda.';
    case 'weak-password':
      return 'Şifre çok zayıf. Lütfen en az 6 karakterli bir şifre belirleyin.';
    case 'operation-not-allowed':
      return 'E-posta/Şifre girişi etkin değil.';
    case 'user-disabled':
      return 'Bu kullanıcı hesabı devre dışı bırakılmış.';
    case 'too-many-requests':
      return 'Çok fazla başarısız deneme. Lütfen bir süre sonra tekrar deneyin.';
    case 'requires-recent-login':
      return 'Bu hassas işlem için yakın zamanda giriş yapmış olmanız gerekir. Lütfen tekrar giriş yapın.';
    case 'invalid-credential':
      return 'E-posta veya şifre hatalı. Lütfen bilgilerinizi kontrol edin.';
    case 'channel-error':
      return 'Lütfen tüm alanları eksiksiz doldurun.';
    default:
      return 'Bir hata oluştu. Lütfen tekrar deneyin.';
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }
  runApp(const MakaleApp());
}

class MakaleApp extends StatefulWidget {
  const MakaleApp({super.key});

  @override
  State<MakaleApp> createState() => _MakaleAppState();
}

class _MakaleAppState extends State<MakaleApp> {
  @override
  void initState() {
    super.initState();
    themeManager.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF3A933F);
    return MaterialApp(
      title: 'Haskayalar Tarım',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.light, primary: seedColor),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        scaffoldBackgroundColor: const Color(0xFFF8FAF8), // Subtle grayish/greenish white
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3A933F), width: 1.5)),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark, primary: seedColor),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: const Color(0xFF0F140F), // Deep forest dark
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3A933F), width: 1.5)),
        ),
      ),
      themeMode: themeManager.themeMode,
      home: const SplashScreen(nextScreen: ArticleListScreen()),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen e-posta ve şifre girin')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(getAuthErrorMessage(e.code))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              Image.asset('assets/logo.png', height: 100),
              const SizedBox(height: 16),
              Text('Haskayalar Tarım', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF3A933F))),
              const SizedBox(height: 8),
              Text('Hoş Geldiniz', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(hintText: 'E-posta'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Şifre'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  backgroundColor: const Color(0xFF3A933F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Giriş Yap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ArticleListScreen extends StatefulWidget {
  const ArticleListScreen({super.key});

  @override
  State<ArticleListScreen> createState() => _ArticleListScreenState();
}

class _ArticleListScreenState extends State<ArticleListScreen> {
  String _role = 'member';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedCategory = "Tümü";
  bool _isLoggedIn = false;
  String? _modalError;

  void _launchWhatsApp() async {
    final doc = await FirebaseFirestore.instance.collection('config').doc('whatsapp').get();
    final data = doc.data() as Map<String, dynamic>?;
    String number = '';
    if (doc.exists && data != null) {
      number = data['number'] ?? '';
    }
    
    if (number.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp numarası ayarlanmamış.')));
      return;
    }
    number = number.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse("https://wa.me/$number");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp başlatılamadı.')));
    }
  }

  void _showSettingsDialog() {
    final controller = TextEditingController();
    FirebaseFirestore.instance.collection('config').doc('whatsapp').get().then((doc) {
      if (doc.exists) controller.text = doc.data()?['number'] ?? '';
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(bCtx).viewInsets.bottom, left: 24, right: 24, top: 24),
        decoration: BoxDecoration(color: Theme.of(bCtx).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sistem Ayarları', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(controller: controller, decoration: const InputDecoration(hintText: 'WhatsApp No (Örn: 905XXXXXXXXX)', prefixIcon: Icon(Icons.phone_android, color: Color(0xFF25D366)))),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('config').doc('whatsapp').set({'number': controller.text});
                if (mounted) Navigator.pop(bCtx);
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: const Color(0xFF3A933F), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Kaydet'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _isLoggedIn = user != null;
          if (user != null) _fetchUserRole(user.uid);
          else _role = 'member';
        });
      }
    });
  }

  void _fetchUserRole(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists && mounted) setState(() => _role = doc.data()?['role'] ?? 'member');
  }

  void _showEditCategoryDialog(String docId, String currentName) {
    final controller = TextEditingController(text: currentName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(bCtx).viewInsets.bottom, left: 24, right: 24, top: 24),
        decoration: BoxDecoration(
          color: Theme.of(bCtx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Kategoriyi Düzenle', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: controller, decoration: const InputDecoration(hintText: 'Kategori Adı')),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.isNotEmpty && controller.text != currentName) {
                  final newName = controller.text;
                  // 1. Update the category itself
                  await FirebaseFirestore.instance.collection('categories').doc(docId).update({'name': newName});
                  
                  // 2. Update all articles with this OLD category name to the NEW category name
                  final articlesRef = FirebaseFirestore.instance.collection('articles');
                  final articlesToUpdate = await articlesRef.where('category', isEqualTo: currentName).get();
                  
                  final batch = FirebaseFirestore.instance.batch();
                  for (var doc in articlesToUpdate.docs) {
                    batch.update(doc.reference, {'category': newName});
                  }
                  await batch.commit();

                  if (mounted) Navigator.pop(bCtx);
                } else {
                  Navigator.pop(bCtx);
                }
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: const Color(0xFF3A933F), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Güncelle'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              children: [
                Container(width: 45, height: 5, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
                if (_modalError != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_modalError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold))),
                        IconButton(icon: const Icon(Icons.close, size: 18, color: Colors.redAccent), onPressed: () => setModalState(() => _modalError = null)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                const Text('Kategori Yönetimi', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(child: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Yeni Kategori Adı'))),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        if (controller.text.isNotEmpty) {
                          await FirebaseFirestore.instance.collection('categories').add({'name': controller.text, 'createdAt': FieldValue.serverTimestamp()});
                          controller.clear();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3A933F), 
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      child: const Text('Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Align(alignment: Alignment.centerLeft, child: Text('MEVCUT KATEGORİLER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2))),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('categories').orderBy('createdAt').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final categories = snapshot.data!.docs;
                      return ListView.separated(
                        padding: const EdgeInsets.only(top: 8),
                        itemCount: categories.length,
                        separatorBuilder: (c, i) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final doc = categories[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(doc['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: IconButton(
                                    icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent, size: 20),
                                    onPressed: () => _showEditCategoryDialog(doc.id, doc['name']),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: IconButton(
                                    icon: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: () async {
                                      final articlesRef = FirebaseFirestore.instance.collection('articles');
                                      final hasArticles = await articlesRef.where('category', isEqualTo: doc['name']).limit(1).get();
                                      
                                      if (hasArticles.docs.isNotEmpty) {
                                        setModalState(() => _modalError = 'Bu kategoride makaleler var!');
                                      } else {
                                        setModalState(() => _modalError = null);
                                        await FirebaseFirestore.instance.collection('categories').doc(doc.id).delete();
                                      }
                                    },
                                  ),
                                ),
                              ],
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
      ),
    );
  }

  void _deleteArticle(BuildContext context, String id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Makaleyi Sil'),
        content: const Text('Bu makaleyi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('İptal')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sil', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('articles').doc(id).delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Makale silindi')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isAdmin = _role == 'admin';

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _launchWhatsApp,
        backgroundColor: const Color(0xFF25D366),
        elevation: 4,
        child: const Icon(Icons.chat, color: Colors.white, size: 32),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/logo.png', height: 48, fit: BoxFit.contain),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: const Color(0xFF3A933F)),
                        onPressed: () => themeManager.toggleTheme(!isDark),
                      ),
                      if (isAdmin) ...[
                        IconButton(icon: const Icon(Icons.settings_outlined, color: Color(0xFF3A933F)), onPressed: _showSettingsDialog),
                        IconButton(icon: const Icon(Icons.category_outlined, color: Color(0xFF3A933F)), onPressed: _showAddCategoryDialog),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF3A933F), size: 32),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditorScreen())),
                        ),
                      ],
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          if (_isLoggedIn) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(role: _role)));
                          } else {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: isDark ? Colors.white10 : const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
                          child: Icon(_isLoggedIn ? Icons.person_outline_rounded : Icons.login_rounded, color: const Color(0xFF3A933F)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  decoration: const InputDecoration(hintText: 'Makale ara...', prefixIcon: Icon(Icons.search), fillColor: Colors.transparent),
                ),
              ),
            ),
            
            // CATEGORIES CHIPS
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('categories').orderBy('createdAt').snapshots(),
                builder: (context, snapshot) {
                  List<String> categories = ["Tümü"];
                  if (snapshot.hasData) {
                    categories.addAll(snapshot.data!.docs.map((d) => d['name'] as String).toList());
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (c, i) => const SizedBox(width: 8),
                    itemBuilder: (c, i) {
                      bool selected = _selectedCategory == categories[i];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = categories[i]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFF3A933F) : (isDark ? Colors.white10 : Colors.white),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [if (!isDark && selected) BoxShadow(color: const Color(0xFF3A933F).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                          ),
                          child: Text(categories[i], style: TextStyle(color: selected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[700]), fontWeight: selected ? FontWeight.bold : FontWeight.w500)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('articles').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  var docs = snapshot.data?.docs ?? [];
                  
                  if (_selectedCategory != "Tümü") {
                    docs = docs.where((d) => (d.data() as Map<String, dynamic>).containsKey('category') && d['category'] == _selectedCategory).toList();
                  }

                  if (_searchQuery.isNotEmpty) {
                    docs = docs.where((d) => (d['title'] as String).toLowerCase().contains(_searchQuery)).toList();
                  }

                  if (docs.isEmpty) return const Center(child: Text('Henüz makale yok'));

                  return ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: docs.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 16),
                    itemBuilder: (c, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleDetailScreen(docId: docs[i].id, title: data['title'], content: data['content'], imageUrl: data['imageUrl']))),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            children: [
                              if (data['imageUrl'] != null)
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                                  child: Image.network(data['imageUrl'], height: 120, width: 120, fit: BoxFit.cover, errorBuilder: (c, e, s) => const SizedBox(width: 120, height: 120)),
                                )
                              else
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[100], borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16))),
                                  child: Icon(Icons.article_outlined, color: Colors.grey[400]),
                                ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(child: Text(data['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                          if (isAdmin)
                                            Row(
                                              children: [
                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.blueAccent),
                                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditorScreen(docId: docs[i].id, initialTitle: data['title'], initialContent: data['content'], initialCategory: data['category'], initialImageUrl: data['imageUrl']))),
                                                ),
                                                const SizedBox(width: 4),
                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  icon: const Icon(Icons.delete_rounded, size: 18, color: Colors.redAccent),
                                                  onPressed: () => _deleteArticle(context, docs[i].id),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                      if (data.containsKey('category')) ...[
                                        const SizedBox(height: 4),
                                        Text(data['category'], style: const TextStyle(color: Color(0xFF3A933F), fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(data['content'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13)),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Daha fazla oku', style: TextStyle(color: Color(0xFF3A933F), fontWeight: FontWeight.bold, fontSize: 12)),
                                          Row(
                                            children: [
                                              const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 14),
                                              const SizedBox(width: 4),
                                              Text('${data['likes'] ?? 0}', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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

class ProfileScreen extends StatefulWidget {
  final String role;
  const ProfileScreen({super.key, required this.role});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;

  Future<void> _reauthenticate(String password) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(credential);
    }
  }


  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(bCtx).viewInsets.bottom, left: 24, right: 24, top: 24),
        decoration: BoxDecoration(
          color: Theme.of(bCtx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Şifre Değiştir', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: oldPasswordController, obscureText: true, decoration: const InputDecoration(hintText: 'Mevcut Şifre')),
            const SizedBox(height: 12),
            TextField(controller: newPasswordController, obscureText: true, decoration: const InputDecoration(hintText: 'Yeni Şifre')),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (oldPasswordController.text.isEmpty || newPasswordController.text.isEmpty) return;
                try {
                  await _reauthenticate(oldPasswordController.text);
                  await FirebaseAuth.instance.currentUser?.updatePassword(newPasswordController.text);
                  if (mounted) {
                    Navigator.pop(bCtx);
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Şifre güncellendi. Lütfen yeni şifrenizle giriş yapın.')));
                    }
                  }
                } on FirebaseAuthException catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(getAuthErrorMessage(e.code))));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bir hata oluştu: $e')));
                }
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: const Color(0xFF3A933F), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Şifreyi Güncelle'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hesabım', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF3A933F)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF3A933F),
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 24),
            itemTile('E-posta', user?.email ?? 'Bilinmiyor', Icons.email_outlined, isDark),
            itemTile('Rol', widget.role.toUpperCase(), Icons.admin_panel_settings_outlined, isDark),
            
            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('GÜVENLİK VE AYARLAR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            ),
            const SizedBox(height: 16),
            
            actionTile('Şifreyi Değiştir', Icons.lock_outline_rounded, isDark, _showChangePasswordDialog),
            
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
                backgroundColor: Colors.redAccent.withOpacity(0.1),
                foregroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Çıkış Yap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget itemTile(String title, String value, IconData icon, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF3A933F)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget actionTile(String title, IconData icon, bool isDark, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF3A933F).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: const Color(0xFF3A933F), size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
      ),
    );
  }
}

class ArticleDetailScreen extends StatefulWidget {
  final String docId;
  final String? title;
  final String? content;
  final String? imageUrl;
  const ArticleDetailScreen({super.key, required this.docId, this.title, this.content, this.imageUrl});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  bool _isLiked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _checkLikeStatus();
  }

  void _checkLikeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final liked = prefs.getBool('liked_${widget.docId}') ?? false;
    
    // Fetch latest like count from Firestore
    final doc = await FirebaseFirestore.instance.collection('articles').doc(widget.docId).get();
    if (mounted) {
      setState(() {
        _isLiked = liked;
        _likeCount = doc.data()?['likes'] ?? 0;
      });
    }
  }

  void _toggleLike() async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      final docRef = FirebaseFirestore.instance.collection('articles').doc(widget.docId);
      
      if (_isLiked) {
        // Unlike
        await docRef.update({'likes': FieldValue.increment(-1)});
        await prefs.setBool('liked_${widget.docId}', false);
        if (mounted) {
          setState(() {
            _isLiked = false;
            _likeCount--;
          });
        }
      } else {
        // Like
        await docRef.update({'likes': FieldValue.increment(1)});
        await prefs.setBool('liked_${widget.docId}', true);
        if (mounted) {
          setState(() {
            _isLiked = true;
            _likeCount++;
          });
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        elevation: 0, 
        iconTheme: const IconThemeData(color: Color(0xFF3A933F)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isLiked ? Colors.redAccent.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: _isLiked ? Colors.redAccent : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_likeCount',
                      style: TextStyle(
                        color: _isLiked ? Colors.redAccent : (isDark ? Colors.grey[400] : Colors.grey[600]),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(widget.imageUrl!, width: double.infinity, height: 250, fit: BoxFit.cover, errorBuilder: (c, e, s) => const SizedBox()),
              ),
              const SizedBox(height: 24),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(widget.title ?? '', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold))),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _toggleLike,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isLiked ? Colors.redAccent : (isDark ? Colors.white10 : Colors.grey[100]),
                      shape: BoxShape.circle,
                      boxShadow: _isLiked ? [BoxShadow(color: Colors.redAccent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                    ),
                    child: Icon(
                      _isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                      color: _isLiked ? Colors.white : const Color(0xFF3A933F),
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(width: 60, height: 4, color: const Color(0xFF3A933F)),
            const SizedBox(height: 24),
            HtmlWidget(widget.content ?? '', textStyle: TextStyle(fontSize: 17, height: 1.6, color: isDark ? Colors.grey[300] : const Color(0xFF374151))),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class EditorScreen extends StatefulWidget {
  final String? docId;
  final String? initialTitle;
  final String? initialContent;
  final String? initialCategory;
  final String? initialImageUrl;
  const EditorScreen({super.key, this.docId, this.initialTitle, this.initialContent, this.initialCategory, this.initialImageUrl});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  String? _selectedCategory;
  XFile? _imageFile;
  String? _imageUrl;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);
    _selectedCategory = widget.initialCategory;
    _imageUrl = widget.initialImageUrl;
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _imageFile = image);
    }
  }

  void _save() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty || _selectedCategory == null) return;
    setState(() => _isLoading = true);
    try {
      String? uploadUrl = _imageUrl;

      if (_imageFile != null) {
        var request = http.MultipartRequest('POST', Uri.parse('http://haskayalartarim.com/upload_image.php'));
        request.files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));
        var response = await request.send();
        
        if (response.statusCode == 200) {
          var responseData = await response.stream.bytesToString();
          var decodedData = json.decode(responseData);
          if (decodedData['status'] == 'success') {
            uploadUrl = decodedData['url'];
          } else {
            throw Exception(decodedData['message']);
          }
        } else {
          throw Exception('Görsel sunucuya yüklenemedi. Durum kodu: ${response.statusCode}');
        }
      }

      final data = {
        'title': _titleController.text,
        'content': _contentController.text,
        'category': _selectedCategory,
        'imageUrl': uploadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (widget.docId == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        data['likes'] = 0;
        await FirebaseFirestore.instance.collection('articles').add(data);
      } else {
        await FirebaseFirestore.instance.collection('articles').doc(widget.docId!).update(data);
      }
      Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text(widget.docId == null ? 'Yeni Makale' : 'Düzenle'), iconTheme: const IconThemeData(color: Color(0xFF3A933F))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF3A933F).withOpacity(0.3), width: 1),
                ),
                child: _imageFile != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(_imageFile!.path), fit: BoxFit.cover))
                    : (_imageUrl != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(_imageUrl!, fit: BoxFit.cover))
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_photo_alternate_rounded, size: 48, color: Color(0xFF3A933F)),
                              const SizedBox(height: 8),
                              Text('Resim Ekle', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontWeight: FontWeight.bold)),
                            ],
                          )),
              ),
            ),
            const SizedBox(height: 24),
            TextField(controller: _titleController, decoration: const InputDecoration(hintText: 'Başlık')),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('categories').orderBy('createdAt').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                var cats = snapshot.data!.docs.map((d) => d['name'] as String).toList();
                return DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  decoration: const InputDecoration(hintText: 'Kategori Seçin'),
                  items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(controller: _contentController, maxLines: 10, decoration: const InputDecoration(hintText: 'İçerik (HTML)')),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60), backgroundColor: const Color(0xFF3A933F), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isLoading ? const CircularProgressIndicator() : const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
