import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../database/app_database.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  final AppDatabase database;

  const LoginScreen({
    super.key,
    required this.database,
  });

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final _emailController =
      TextEditingController(
    text: 'admin@servihogar.com',
  );

  final _passwordController =
      TextEditingController(
    text: '123456',
  );

  bool _cargando = false;
  bool _mostrarPassword = false;
  String? _error;

  Future<void> _iniciarSesion() async {
    if (_cargando) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final exito =
          await AuthService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (exito) {
        Navigator.of(context)
            .pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                HomeScreen(
              database:
                  widget.database,
            ),
          ),
        );
      } else {
        setState(() {
          _error =
              'Las credenciales ingresadas no son correctas.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error =
            'No se pudo conectar con el servidor.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    return Scaffold(
      backgroundColor:
          const Color(0xFF09090F),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context)
                .unfocus();
          },
          child:
              SingleChildScrollView(
            physics:
                const BouncingScrollPhysics(),
            padding:
                const EdgeInsets.fromLTRB(
              24,
              28,
              24,
              32,
            ),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 520,
              ),
              child: Column(
                children: [
                  const SizedBox(
                    height: 18,
                  ),
                  _buildBrand(),
                  const SizedBox(
                    height: 38,
                  ),
                  _buildLoginCard(
                    context,
                    theme,
                    colors,
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  _buildSecurityInfo(),
                  const SizedBox(
                    height: 28,
                  ),
                  Text(
                    '${AppConfig.appName} · Servicios para tu hogar',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color:
                          const Color(
                        0xFF9A98A8,
                      ).withValues(
                        alpha: 0.75,
                      ),
                      fontSize: 11.5,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrand() {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration:
              BoxDecoration(
            gradient:
                const LinearGradient(
              colors: [
                Color(0xFF7C3AED),
                Color(0xFF4F46E5),
              ],
              begin:
                  Alignment.topLeft,
              end:
                  Alignment.bottomRight,
            ),
            borderRadius:
                BorderRadius.circular(
              27,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    const Color(
                  0xFF8B5CF6,
                ).withValues(
                  alpha: 0.28,
                ),
                blurRadius: 28,
                offset:
                    const Offset(
                  0,
                  12,
                ),
              ),
            ],
          ),
          child: Stack(
            alignment:
                Alignment.center,
            children: [
              Positioned(
                right: -8,
                top: -10,
                child: Container(
                  width: 45,
                  height: 45,
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white
                            .withValues(
                      alpha: 0.08,
                    ),
                    shape:
                        BoxShape.circle,
                  ),
                ),
              ),
              const Icon(
                Icons
                    .home_repair_service_rounded,
                color:
                    Colors.white,
                size: 42,
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        const Text(
          'ServiHogar',
          style: TextStyle(
            color:
                Color(0xFFF8F7FF),
            fontSize: 29,
            fontWeight:
                FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(
          height: 3,
        ),
        const Text(
          'CONNECT',
          style: TextStyle(
            color:
                Color(0xFF8B5CF6),
            fontSize: 12,
            fontWeight:
                FontWeight.w800,
            letterSpacing: 3.2,
          ),
        ),
        const SizedBox(
          height: 12,
        ),
        Text(
          'Servicios para tu hogar,\n'
          'fácil, seguro y confiable.',
          textAlign:
              TextAlign.center,
          style: TextStyle(
            color:
                const Color(
              0xFF9A98A8,
            ).withValues(
              alpha: 0.95,
            ),
            fontSize: 14,
            height: 1.5,
            fontWeight:
                FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colors,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(
        22,
        24,
        22,
        22,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFF12121B),
        borderRadius:
            BorderRadius.circular(
          24,
        ),
        border: Border.all(
          color:
              const Color(0xFF252431),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(
              alpha: 0.20,
            ),
            blurRadius: 30,
            offset:
                const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Bienvenido',
            style: TextStyle(
              color:
                  Color(0xFFF8F7FF),
              fontSize: 23,
              fontWeight:
                  FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(
            height: 6,
          ),
          const Text(
            'Ingresa a tu cuenta para continuar.',
            style: TextStyle(
              color:
                  Color(0xFF9A98A8),
              fontSize: 13,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
          const SizedBox(
            height: 25,
          ),
          _buildEmailField(),
          const SizedBox(
            height: 15,
          ),
          _buildPasswordField(),
          if (_error != null) ...[
            const SizedBox(
              height: 16,
            ),
            _buildErrorMessage(),
          ],
          const SizedBox(
            height: 22,
          ),
          _buildLoginButton(),
          const SizedBox(
            height: 17,
          ),
          Row(
            children: [
              Expanded(
                child: Divider(
                  color:
                      const Color(
                    0xFF252431,
                  ),
                  thickness: 1,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 12,
                ),
                child: Text(
                  'ACCESO SEGURO',
                  style: TextStyle(
                    color:
                        const Color(
                      0xFF9A98A8,
                    ).withValues(
                      alpha: 0.65,
                    ),
                    fontSize: 9.5,
                    fontWeight:
                        FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color:
                      const Color(
                    0xFF252431,
                  ),
                  thickness: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller:
          _emailController,
      keyboardType:
          TextInputType.emailAddress,
      textInputAction:
          TextInputAction.next,
      style:
          const TextStyle(
        color:
            Color(0xFFF8F7FF),
        fontSize: 14,
        fontWeight:
            FontWeight.w500,
      ),
      decoration:
          InputDecoration(
        labelText:
            'Correo electrónico',
        hintText:
            'ejemplo@correo.com',
        prefixIcon:
            const Icon(
          Icons.email_outlined,
          size: 21,
        ),
        filled: true,
        fillColor:
            const Color(
          0xFF1A1925,
        ),
        contentPadding:
            const EdgeInsets
                .symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            15,
          ),
          borderSide:
              const BorderSide(
            color:
                Color(0xFF252431),
          ),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            15,
          ),
          borderSide:
              const BorderSide(
            color:
                Color(0xFF252431),
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            15,
          ),
          borderSide:
              const BorderSide(
            color:
                Color(0xFF8B5CF6),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller:
          _passwordController,
      obscureText:
          !_mostrarPassword,
      textInputAction:
          TextInputAction.done,
      onSubmitted: (_) {
        if (!_cargando) {
          _iniciarSesion();
        }
      },
      style:
          const TextStyle(
        color:
            Color(0xFFF8F7FF),
        fontSize: 14,
        fontWeight:
            FontWeight.w500,
      ),
      decoration:
          InputDecoration(
        labelText:
            'Contraseña',
        hintText:
            'Ingresa tu contraseña',
        prefixIcon:
            const Icon(
          Icons.lock_outline_rounded,
          size: 21,
        ),
        suffixIcon:
            IconButton(
          tooltip:
              _mostrarPassword
                  ? 'Ocultar contraseña'
                  : 'Mostrar contraseña',
          onPressed: () {
            setState(() {
              _mostrarPassword =
                  !_mostrarPassword;
            });
          },
          icon: Icon(
            _mostrarPassword
                ? Icons
                    .visibility_off_outlined
                : Icons
                    .visibility_outlined,
            size: 21,
          ),
        ),
        filled: true,
        fillColor:
            const Color(
          0xFF1A1925,
        ),
        contentPadding:
            const EdgeInsets
                .symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            15,
          ),
          borderSide:
              const BorderSide(
            color:
                Color(0xFF252431),
          ),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            15,
          ),
          borderSide:
              const BorderSide(
            color:
                Color(0xFF252431),
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            15,
          ),
          borderSide:
              const BorderSide(
            color:
                Color(0xFF8B5CF6),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 12,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFEF4444)
                .withValues(
          alpha: 0.10,
        ),
        borderRadius:
            BorderRadius.circular(
          13,
        ),
        border: Border.all(
          color:
              const Color(0xFFEF4444)
                  .withValues(
            alpha: 0.25,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color:
                Color(0xFFF87171),
            size: 20,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              _error!,
              style:
                  const TextStyle(
                color:
                    Color(0xFFFCA5A5),
                fontSize: 12.5,
                height: 1.35,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 53,
      child: DecoratedBox(
        decoration:
            BoxDecoration(
          gradient:
              const LinearGradient(
            colors: [
              Color(0xFF8B5CF6),
              Color(0xFF6366F1),
            ],
            begin:
                Alignment.centerLeft,
            end:
                Alignment.centerRight,
          ),
          borderRadius:
              BorderRadius.circular(
            15,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  const Color(
                0xFF8B5CF6,
              ).withValues(
                alpha: 0.24,
              ),
              blurRadius: 18,
              offset:
                  const Offset(0, 8),
            ),
          ],
        ),
        child:
            ElevatedButton(
          onPressed:
              _cargando
                  ? null
                  : _iniciarSesion,
          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                Colors.transparent,
            foregroundColor:
                Colors.white,
            disabledBackgroundColor:
                Colors.transparent,
            disabledForegroundColor:
                Colors.white70,
            shadowColor:
                Colors.transparent,
            elevation: 0,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                15,
              ),
            ),
          ),
          child: _cargando
              ? const SizedBox(
                  width: 23,
                  height: 23,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<
                            Color>(
                      Colors.white,
                    ),
                  ),
                )
              : const Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  children: [
                    Icon(
                      Icons
                          .login_rounded,
                      size: 20,
                    ),
                    SizedBox(
                      width: 9,
                    ),
                    Text(
                      'Iniciar sesión',
                      style:
                          TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration:
              BoxDecoration(
            color:
                const Color(
              0xFF22C55E,
            ).withValues(
              alpha: 0.10,
            ),
            shape:
                BoxShape.circle,
          ),
          child: const Icon(
            Icons
                .verified_user_outlined,
            color:
                Color(0xFF22C55E),
            size: 18,
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        const Flexible(
          child: Text(
            'Tu sesión se almacena de forma segura',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color:
                  Color(0xFF9A98A8),
              fontSize: 11.5,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}