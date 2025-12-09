import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentDetailScreen extends StatefulWidget {
  final String userId;
  const StudentDetailScreen({super.key, required this.userId});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final _db = FirebaseFirestore.instance;

  Map<String, dynamic>? userData;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final doc = await _db.collection("usuarios").doc(widget.userId).get();
    userData = doc.data();
    setState(() => cargando = false);
  }

  // Modal: editar campo
  void showEditModal({
    required String fieldName,
    required String label,
    required dynamic initialValue,
    required bool isDropdown,
    Future<List<Map<String, String>>> Function()? fetchOptions,
    bool editable = true,
  }) {
    if (!editable) return;

    final ctrl = TextEditingController(text: initialValue?.toString() ?? "");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 25,
          ),
          child: FutureBuilder<List<Map<String, String>>>(
            future: isDropdown ? fetchOptions!() : Future.value([]),
            builder: (context, snap) {
              final options = snap.data ?? [];

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Editar $label",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!isDropdown)
                    TextField(
                      controller: ctrl,
                      decoration: InputDecoration(
                        labelText: label,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  if (isDropdown)
                    DropdownButtonFormField<String>(
                      value: initialValue?.toString(),
                      decoration:
                          const InputDecoration(labelText: "Seleccione"),
                      items: options
                          .map(
                            (opt) => DropdownMenuItem(
                              value: opt["id"],
                              child: Text(opt["nombre"]!),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => ctrl.text = v ?? "",
                    ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        child: const Text(
                          "Cancelar",
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          await _db
                              .collection("usuarios")
                              .doc(widget.userId)
                              .update({fieldName: ctrl.text.trim()});

                          Navigator.pop(context);
                          loadUser();
                        },
                        child: const Text(
                          "Guardar",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void showDeactivateModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Desactivar estudiante",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Esto desactivará al estudiante, pero no eliminará sus datos.",
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    child: const Text("Cancelar"),
                    onPressed: () => Navigator.pop(context),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      "Desactivar",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () async {
                      await _db
                          .collection("usuarios")
                          .doc(widget.userId)
                          .update({"activo": false});

                      Navigator.pop(context);
                      loadUser();
                    },
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }

  void showReactivateModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Reactivar estudiante",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text("El estudiante podrá volver a acceder."),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    child: const Text("Cancelar"),
                    onPressed: () => Navigator.pop(context),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      "Reactivar",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () async {
                      await _db
                          .collection("usuarios")
                          .doc(widget.userId)
                          .update({"activo": true});

                      Navigator.pop(context);
                      loadUser();
                    },
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final u = userData ?? {};
    final nombre = (u["nombre"] ?? "") as String;
    final email = (u["email"] ?? "") as String;
    final division = (u["division_actual"] ?? "") as String;
    final curso = (u["curso_actual"] ?? "") as String;
    final rol = (u["rol"] ?? "") as String;
    final racha = u["racha"]?.toString() ?? "0";
    final activo = u["activo"] == true;

    return Scaffold(
      backgroundColor: const Color(0xFFF8EEDA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D2034),
        title: const Text(
          "Detalle del estudiante",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8EEDA), Color(0xFFF2DFBF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          children: [
            _headerCard(nombre, email, rol, activo),
            const SizedBox(height: 16),
            _infoGrid(division, curso, racha),
            const SizedBox(height: 16),
            _editableSection(u),
            const SizedBox(height: 18),
            _statusAction(activo),
          ],
        ),
      ),
    );
  }

  Widget _headerCard(String nombre, String email, String rol, bool activo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _avatar(nombre),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre.isNotEmpty ? nombre : "Sin nombre",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email.isNotEmpty ? email : "Sin correo",
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _pill("Rol: ${rol.isEmpty ? 'N/D' : rol}"),
                    _pill(activo ? "Activo" : "Inactivo",
                        color: activo
                            ? const Color(0xFFE3F7E5)
                            : const Color(0xFFFFE4E4),
                        textColor: activo
                            ? const Color(0xFF2D8A47)
                            : const Color(0xFFB83A3A)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _infoGrid(String division, String curso, String racha) {
    return Row(
      children: [
        Expanded(
          child: _infoTile(
            icon: Icons.account_tree,
            label: "División",
            value: division.isEmpty ? "No asignada" : division,
            onEdit: () => showEditModal(
              fieldName: "division_actual",
              label: "División",
              initialValue: division,
              isDropdown: true,
              fetchOptions: () async {
                final snap =
                    await _db.collection("divisiones").orderBy("nombre").get();
                return snap.docs
                    .map((d) => {
                          "id": d.id.toString(),
                          "nombre": d["nombre"].toString()
                        })
                    .toList();
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _infoTile(
            icon: Icons.school,
            label: "Curso",
            value: curso.isEmpty ? "No asignado" : curso,
            editable: false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _infoTile(
            icon: Icons.local_fire_department,
            label: "Racha",
            value: "$racha días",
            editable: false,
          ),
        ),
      ],
    );
  }

  Widget _editableSection(Map<String, dynamic> u) {
    return Column(
      children: [
        _fieldCard(
          label: "Nombre",
          value: u["nombre"] ?? "",
          onEdit: () => showEditModal(
            fieldName: "nombre",
            label: "Nombre",
            initialValue: u["nombre"],
            isDropdown: false,
          ),
        ),
        _fieldCard(
          label: "Email",
          value: u["email"] ?? "",
          editable: false,
        ),
        _fieldCard(
          label: "Rol",
          value: u["rol"] ?? "",
          onEdit: () => showEditModal(
            fieldName: "rol",
            label: "Rol",
            initialValue: u["rol"],
            isDropdown: true,
            fetchOptions: () async => [
              {"id": "estudiante", "nombre": "Estudiante"},
              {"id": "admin", "nombre": "Administrador"},
            ],
          ),
        ),
      ],
    );
  }

  Widget _fieldCard({
    required String label,
    required String value,
    bool editable = true,
    VoidCallback? onEdit,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : "No definido",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (editable)
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFFFFA200)),
              onPressed: onEdit,
            ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    bool editable = true,
    VoidCallback? onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFFFFA200)),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              if (editable)
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE4B8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "Editar",
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusAction(bool activo) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: activo ? Colors.red : Colors.green,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      onPressed: activo ? showDeactivateModal : showReactivateModal,
      child: Text(
        activo ? "Desactivar estudiante" : "Reactivar estudiante",
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _avatar(String name) {
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : "?";
    return Container(
      height: 52,
      width: 52,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFFFA200),
      ),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _pill(String text, {Color color = const Color(0xFFF2F4F8), Color textColor = Colors.black87}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
