import 'package:flutter/material.dart';
import '../../core/models/customer.dart';
import '../../core/repositories/customer_repository.dart';

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  final CustomerRepository _repository = CustomerRepository();
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _ciController = TextEditingController();
  final _telefonoController = TextEditingController();
  List<Customer> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    _customers = await _repository.getAllCustomers();
    setState(() => _isLoading = false);
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      try {
        final customer = Customer(nombre: _nombreController.text.trim(), carnetIdentidad: _ciController.text.trim(), telefono: _telefonoController.text.trim());
        await _repository.createCustomer(customer);
        _formKey.currentState!.reset();
        await _loadCustomers();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Cliente registrado'), backgroundColor: Colors.green));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes'), centerTitle: true),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Nombre *', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Requerido' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _ciController, decoration: const InputDecoration(labelText: 'Carnet de Identidad *', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Requerido' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _telefonoController, decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()), validator: (v) => null, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: ElevatedButton.icon(onPressed: _saveCustomer, icon: const Icon(Icons.add), label: const Text('AÑADIR'), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(onPressed: () => _formKey.currentState!.reset(), icon: const Icon(Icons.clear), label: const Text('LIMPIAR'), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[400], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)))),
            ]),
          ]),
        )),
        const Divider(),
        Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator()) : _customers.isEmpty ? const Center(child: Text('No hay clientes registrados')) : ListView.builder(
          itemCount: _customers.length,
          itemBuilder: (ctx, i) {
            final c = _customers[i];
            return Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white)),
              title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('CI: ${c.carnetIdentidad}'), Text('📞 ${c.telefono}')]),
            ));
          },
        )),
      ]),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _ciController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }
}
