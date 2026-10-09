import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:home_widget/home_widget.dart';
import 'dart:convert';

void main() => runApp(MiMonitorApp());

class MiMonitorApp extends StatefulWidget {
  @override
  _MiMonitorAppState createState() => _MiMonitorAppState();
}

class _MiMonitorAppState extends State<MiMonitorApp> {
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

  String rawFDolar = "", rawFEuro = "", rawFUsdt = "";

  String monedaSeleccionada = 'USD'; 
  bool deDivisaABs = true;
  TextEditingController controller = TextEditingController();
  double resultado = 0.0;

  @override
  void initState() { 
    super.initState(); 
    _inicializarApp(); 
  }

  Future<void> _inicializarApp() async {
    await cargarDatosLocales();
    await actualizarTasas();
  }

  Future<void> cargarDatosLocales() async {
    try {
      String? sDolar = await HomeWidget.getWidgetData<String>('precio_dolar');
      String? sEuro = await HomeWidget.getWidgetData<String>('precio_euro');
      String? sUsdt = await HomeWidget.getWidgetData<String>('precio_usdt');
      String? fD = await HomeWidget.getWidgetData<String>('raw_f_dolar');
      String? fE = await HomeWidget.getWidgetData<String>('raw_f_euro');
      String? fU = await HomeWidget.getWidgetData<String>('raw_f_usdt');

      if (sDolar != null && sEuro != null && sUsdt != null) {
        setState(() {
          precioDolar = double.tryParse(sDolar) ?? 0.0;
          precioEuro = double.tryParse(sEuro) ?? 0.0;
          precioUsdt = double.tryParse(sUsdt) ?? 0.0;
          rawFDolar = fD ?? "";
          rawFEuro = fE ?? "";
          rawFUsdt = fU ?? "";
        });
        recalcular(controller.text);
      }
    } catch (e) {
      print("Error leyendo caché local: $e");
    }
  }

  Future<void> actualizarTasas() async {
    await fetchTasa('https://ve.dolarapi.com/v1/dolares/oficial', 'USD');
    await fetchTasa('https://ve.dolarapi.com/v1/euros', 'EUR');
    await fetchTasa('https://ve.dolarapi.com/v1/dolares/paralelo', 'USDT');
    recalcular(controller.text);

    // Guardado local tanto para el modo sin conexión como para el widget nativo
    await HomeWidget.saveWidgetData<String>('precio_dolar', precioDolar.toString());
    await HomeWidget.saveWidgetData<String>('precio_euro', precioEuro.toString());
    await HomeWidget.saveWidgetData<String>('precio_usdt', precioUsdt.toString());
    await HomeWidget.saveWidgetData<String>('raw_f_dolar', rawFDolar);
    await HomeWidget.saveWidgetData<String>('raw_f_euro', rawFEuro);
    await HomeWidget.saveWidgetData<String>('raw_f_usdt', rawFUsdt);

    await HomeWidget.saveWidgetData<String>('widget_dolar', formatearDecimal(precioDolar));
    await HomeWidget.saveWidgetData<String>('widget_euro', formatearDecimal(precioEuro));
    await HomeWidget.saveWidgetData<String>('widget_usdt', formatearDecimal(precioUsdt));
    await HomeWidget.saveWidgetData<String>('widget_fecha', formatearFecha(rawFDolar));
    await HomeWidget.updateWidget(name: 'AppWidgetProvider');
  }

  String formatearFecha(String fechaIso) {
    try {
      DateTime dt = DateTime.parse(fechaIso);
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    } catch (e) { 
      return "---"; 
    }
  }

  String formatearDecimal(double valor) {
    return valor.toStringAsFixed(2).replaceAll('.', ',');
  }

  Future<void> fetchTasa(String url, String tipo) async {
    try {
      final res = await http.get(Uri.parse(url)).timeout(Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          double v = 0.0; 
          String f = "";
          if (data is List) {
            var oficial = data.firstWhere((item) => item['fuente'] == 'oficial');
            v = double.parse(oficial['promedio'].toString());
            f = oficial['fechaActualizacion'];
          } else {
            v = double.parse(data['promedio'].toString());
            f = data['fechaActualizacion'];
          }
          if (tipo == 'USD') { precioDolar = v; rawFDolar = f; }
          if (tipo == 'EUR') { precioEuro = v; rawFEuro = f; }
          if (tipo == 'USDT') { precioUsdt = v; rawFUsdt = f; }
        });
      }
    } catch (e) { 
      print("No se pudo obtener tasa ($tipo): $e"); 
    }
  }

  void recalcular(String valor) {
    double monto = double.tryParse(valor.replaceAll(',', '.')) ?? 0.0;
    double tasa = (monedaSeleccionada == 'USD') ? precioDolar : 
                  (monedaSeleccionada == 'EUR') ? precioEuro : precioUsdt;
    
    setState(() {
      if (tasa == 0) { resultado = 0; return; }
      if (deDivisaABs) {
        resultado = monto * tasa;
      } else {
        resultado = monto / tasa;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tasas de Venezuela"),
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
            _cardPrecio("Dólar BCV", precioDolar, Icons.attach_money, Colors.blue, formatearFecha(rawFDolar)),
            _cardPrecio("Euro BCV", precioEuro, Icons.euro, Colors.green, formatearFecha(rawFEuro)),
            _cardPrecio("USDT Binance", precioUsdt, Icons.currency_bitcoin, Colors.orange, formatearFecha(rawFUsdt)),
            
            Divider(height: 35),
            
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

            SizedBox(height: 15),

            _cajaResultado(),

            SizedBox(height: 15),
            TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: deDivisaABs ? "Monto en $monedaSeleccionada" : "Monto en Bolívares (VES)",
                prefixIcon: Icon(deDivisaABs ? Icons.money : Icons.account_balance_wallet),
              ),
              onChanged: recalcular,
            ),

            SizedBox(height: 30),
            Text(
              "Hecho por David Valenzuela",
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 0.5,
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _cajaResultado() {
    String unidad = deDivisaABs ? "VES" : monedaSeleccionada;
    String montoFormateado = formatearDecimal(resultado);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Resultado:", style: TextStyle(fontSize: 14)),
              IconButton(
                tooltip: "Copiar resultado",
                icon: Icon(Icons.copy, size: 20, color: Theme.of(context).colorScheme.primary),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: montoFormateado));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Monto copiado: $montoFormateado"),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
          SelectableText(
            "$montoFormateado $unidad",
            style: TextStyle(
              fontSize: 30, 
              fontWeight: FontWeight.bold, 
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
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
        subtitle: Text("Fecha: $f"),
        trailing: Text(v == 0.0 ? "..." : "Bs. ${formatearDecimal(v)}", 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}