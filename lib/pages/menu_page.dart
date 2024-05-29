import 'package:flutter/material.dart';

import '../widgets/animations.dart';
import 'default_page.dart';
import 'favorite_trips_page.dart';

class NavBar extends StatelessWidget {
  const NavBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white, // Drawer arka plan rengi beyaz
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              width: 60.0,
              height: 60.0,
              // İsterseniz child widget ekleyebilirsiniz
            ),

            ListTile(
              leading: const Icon(Icons.favorite,color: Colors.red,size: 50),
              title: const Text(
                'Favoriler',
                style: TextStyle(color: Colors.black), // Metin rengi siyah
              ),
              onTap: () {
                Navigator.pop(context); // Menüyü kapat
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FavTripsPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.share,color: Colors.amber,size: 50,),
              title: const Text(
                'Paylaş',
                style: TextStyle(color: Colors.black), // Metin rengi siyah
              ),
              onTap: () {
                // Paylaşım işlemleri
                Navigator.pop(context); // Menüyü kapat
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings,color: Colors.cyanAccent,size: 50),
              title: const Text(
                'Ayarlar',
                style: TextStyle(color: Colors.black), // Metin rengi siyah
              ),
              onTap: () {
                Navigator.pop(context); // Menüyü kapat
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>  const defaultPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.description,color: Colors.deepPurpleAccent,size: 50),
              title: const Text(
                'Hakkında',
                style: TextStyle(color: Colors.black,), // Metin rengi siyah
              ),
              onTap: () {
                Navigator.pop(context); // Menüyü kapat
                Navigator.of(context).push(SlideRightRoute(widget: const defaultPage()),

                );
              },
            ),
            const Divider(),

            ListTile(
              title: const Text(
                'Çıkış yap ',
                style: TextStyle(color: Colors.black), // Metin rengi siyah
              ),
              leading: const Icon(Icons.exit_to_app,color: Colors.black,size: 50),
              onTap: () {
                // Çıkış işlemleri
                Navigator.pop(context); // Menüyü kapat
              },
            ),
          ],
        ),
      ),
    );

  }
}
