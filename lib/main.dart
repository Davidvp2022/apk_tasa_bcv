import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MiMonitorApp());

class MiMonitorApp extends StatefulWidget {
  @override
  _MiMonitorAppState createState() => _MiMonitorAppState();
}

class _MiMonitorAppState extends State<MiMonitorApp> {
  // Variable para controlar el tema (Claro/Oscuro)
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.light, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorSchemeSeed: Colors.indigo),
      themeMode: _themeMode,
      home: MonitorTasas(onThemeToggle: toggleTheme),
    );
  }
}

class MonitorTasas extends StatefulWidget {
  final VoidCallback onThemeToggle;
  MonitorTasas({required this.onThemeToggle});

  @override
  _MonitorTasasState createState() => _MonitorTasasState();
}

class _MonitorTasasState extends State<MonitorTasas> {
  double precioDolar = 0.0;
  double precioEuro = 0.0;
  double precioUsdt = 0.0; 
  String fDolar = "", fEuro = "", fUsdt = "";

  String monedaSeleccionada = 'USD'; 
  bool deDivisaABs = true; // Controla la dirección de la calculadora
  TextEditingController controller = TextEditingController();
  double resultado = 0.0;

  Future<void> actualizarTasas() async {
    await fetchTasa('https://ve.dolarapi.com/v1/dolares/oficial', 'USD');
    await fetchTasa('https://ve.dolarapi.com/v1/euros', 'EUR');
    await fetchTasa('https://ve.dolarapi.com/v1/dolares/paralelo', 'USDT');
    recalcular(controller.text);
  }

  String formatearFecha(String fechaIso, bool esBcv) {
    try {
      DateTime dt = DateTime.parse(fechaIso);
      if (esBcv) {
        if (dt.weekday == DateTime.friday) dt = dt.add(Duration(days: 3));
        else if (dt.weekday == DateTime.saturday) dt = dt.add(Duration(days: 2));
        else dt = dt.add(Duration(days: 1));
      }
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    } catch (e) { return "---"; }
  }

  Future<void> fetchTasa(String url, String tipo) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          double v = 0.0; String f = "";
          if (data is List) {
            var oficial = data.firstWhere((item) => item['fuente'] == 'oficial');
            v = double.parse(oficial['promedio'].toString());
            f = oficial['fechaActualizacion'];
          } else {
            v = double.parse(data['promedio'].toString());
            f = data['fechaActualizacion'];
          }
          if (tipo == 'USD') { precioDolar = v; fDolar = formatearFecha(f, true); }
          if (tipo == 'EUR') { precioEuro = v; fEuro = formatearFecha(f, true); }
          if (tipo == 'USDT') { precioUsdt = v; fUsdt = formatearFecha(f, false); }
        });
      }
    } catch (e) { print(e); }
  }

  void recalcular(String valor) {
    double monto = double.tryParse(valor) ?? 0.0;
    double tasa = (monedaSeleccionada == 'USD') ? precioDolar : 
                  (monedaSeleccionada == 'EUR') ? precioEuro : precioUsdt;
    
    setState(() {
      if (tasa == 0) { resultado = 0; return; }
      // Lógica de dirección
      if (deDivisaABs) {
        resultado = monto * tasa;
      } else {
        resultado = monto / tasa;
      }
    });
  }

  @override
  void initState() { super.initState(); actualizarTasas(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tasas de Venezuela 🇻🇪"),
        actions: [
          IconButton(
            icon: Icon(Theme.of(context).brightness == Brightness.light ? Icons.dark_mode : Icons.light_mode),
            onPressed: widget.onThemeToggle,
          ),
          IconButton(icon: Icon(Icons.refresh), onPressed: actualizarTasas),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            _cardPrecio("Dólar BCV", precioDolar, Icons.attach_money, Colors.green, fDolar),
            _cardPrecio("Euro BCV", precioEuro, Icons.euro, Colors.blue, fEuro),
            _cardPrecio("USDT Promedio", precioUsdt, Icons.currency_bitcoin, Colors.orange, fUsdt),
            
            Divider(height: 40),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Calculadora", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ActionChip(
                  avatar: Icon(Icons.swap_horiz, size: 16),
                  label: Text(deDivisaABs ? "Divisa a Bs" : "Bs a Divisa"),
                  onPressed: () {
                    setState(() => deDivisaABs = !deDivisaABs);
                    recalcular(controller.text);
                  },
                ),
              ],
            ),
            
            SizedBox(height: 10),
            ToggleButtons(
              isSelected: [monedaSeleccionada == 'USD', monedaSeleccionada == 'EUR', monedaSeleccionada == 'USDT'],
              onPressed: (int index) {
                setState(() {
                  monedaSeleccionada = index == 0 ? 'USD' : index == 1 ? 'EUR' : 'USDT';
                  recalcular(controller.text);
                });
              },
              borderRadius: BorderRadius.circular(10),
              children: [
                Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("USD")),
                Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("EUR")),
                Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("USDT")),
              ],
            ),

            SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: deDivisaABs ? "Monto en $monedaSeleccionada" : "Monto en Bolívares (VES)",
                prefixIcon: Icon(deDivisaABs ? Icons.money : Icons.account_balance_wallet),
              ),
              onChanged: recalcular,
            ),
            
            SizedBox(height: 20),
            _cajaResultado(),
          ],
        ),
      ),
    );
  }

  Widget _cajaResultado() {
    String unidad = deDivisaABs ? "VES" : monedaSeleccionada;
    return Container(
      padding: EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text("Resultado:", style: TextStyle(fontSize: 14)),
          Text("${resultado.toStringAsFixed(2)} $unidad", 
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
        ],
      ),
    );
  }

  Widget _cardPrecio(String t, double v, IconData i, Color c, String f) {
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: c, child: Icon(i, color: Colors.white)),
        title: Text(t, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("$f"),
        trailing: Text(v == 0.0 ? "..." : "Bs. ${v.toStringAsFixed(2)}", 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}