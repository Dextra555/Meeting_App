// import 'package:flutter/material.dart';
//
// import 'cilentformsubmission.dart';
// import 'dashboardscreen.dart';
//
// class MainAppScaffold extends StatefulWidget {
//   const MainAppScaffold({super.key});
//
//   @override
//   State<MainAppScaffold> createState() => _MainAppScaffoldState();
// }
//
// class _MainAppScaffoldState extends State<MainAppScaffold> {
//   int _currentIndex = 0;
//
//   final List<Widget> _pages = [
//     const DashboardScreen(),
//     const ClientFormScreen(),
//     const Center(child: Text('⏱ Time Page', style: TextStyle(fontSize: 20))),
//     const Center(child: Text('👤 Profile Page', style: TextStyle(fontSize: 20))),
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _pages[_currentIndex],
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _currentIndex,
//         selectedItemColor: Colors.blue,
//         unselectedItemColor: Colors.grey,
//         backgroundColor: Colors.white,
//         showSelectedLabels: true,
//         showUnselectedLabels: true,
//         type: BottomNavigationBarType.fixed,
//         elevation: 8,
//         onTap: (index) {
//           setState(() {
//             _currentIndex = index;
//           });
//         },
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//           BottomNavigationBarItem(icon: Icon(Icons.assignment_ind_outlined), label: 'Client'),
//           BottomNavigationBarItem(icon: Icon(Icons.access_time), label: 'Time'),
//           BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
//         ],
//       ),
//     );
//   }
// }
