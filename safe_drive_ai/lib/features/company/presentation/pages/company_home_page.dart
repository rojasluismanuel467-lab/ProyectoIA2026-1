import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/company_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/company_bloc.dart';
import 'company_drivers_page.dart';
import 'company_invitations_page.dart';
import 'company_profile_page.dart';
import 'company_pending_trips_page.dart';
import 'company_trip_history_page.dart';

/// Pantalla principal de la empresa con BottomNavigationBar de 3 pestanas:
///   0 — Conductores
///   1 — Invitaciones
///   2 — Perfil
///
/// Provee [CompanyBloc] para todos los tabs hijos.
/// El [AuthBloc] ya viene provisto desde main.dart.
class CompanyHomePage extends StatefulWidget {
  const CompanyHomePage({super.key, required this.company});

  final CompanyEntity company;

  @override
  State<CompanyHomePage> createState() => _CompanyHomePageState();
}

class _CompanyHomePageState extends State<CompanyHomePage> {
  int _currentIndex = 0;

  static const List<_TabMeta> _tabs = [
    _TabMeta(
      label: 'Conductores',
      icon: Icons.people_outline,
      activeIcon: Icons.people,
    ),
    _TabMeta(
      label: 'Aprobaciones',
      icon: Icons.playlist_add_check_circle_outlined,
      activeIcon: Icons.playlist_add_check_circle,
    ),
    _TabMeta(
      label: 'Invitaciones',
      icon: Icons.mail_outline,
      activeIcon: Icons.mail,
    ),
    _TabMeta(
      label: 'Perfil',
      icon: Icons.business_outlined,
      activeIcon: Icons.business,
    ),
    _TabMeta(
      label: 'Historial',
      icon: Icons.history,
      activeIcon: Icons.history,
    ),
  ];

  String get _currentTitle {
    if (_currentIndex >= 0 && _currentIndex < _tabs.length) {
      return _tabs[_currentIndex].label;
    }
    return 'Safe Drive AI';
  }

  void _showDriverActionSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Agregar conductor',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 16),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primarySurface,
                    child: Icon(
                      Icons.person_add_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text(
                    'Registrar conductor nuevo',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: const Text(
                    'El conductor aún no tiene cuenta en Safe Drive AI',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push(
                      '/company/register-driver',
                      extra: {
                        'companyId': widget.company.id,
                        'companyName': widget.company.name,
                      },
                    );
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primarySurface,
                    child: Icon(
                      Icons.mail_outline,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text(
                    'Invitar conductor existente',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: const Text(
                    'El conductor ya tiene una cuenta en Safe Drive AI',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() => _currentIndex = 2);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoggedOut) {
          context.go('/role-selection');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          leading: Builder(
            builder: (BuildContext scaffoldContext) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnPrimary,
                ),
              ),
              Text(
                widget.company.name,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        drawer: _buildDrawer(),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            CompanyDriversPage(
              companyId: widget.company.id,
              companyName: widget.company.name,
            ),
            CompanyPendingTripsPage(
              companyId: widget.company.id,
            ),
            CompanyInvitationsPage(
              companyId: widget.company.id,
              companyName: widget.company.name,
            ),
            CompanyProfilePage(company: widget.company),
            CompanyTripHistoryPage(companyId: widget.company.id),
          ],
        ),
        floatingActionButton: _currentIndex == 0
            ? FloatingActionButton.extended(
                onPressed: () => _showDriverActionSheet(context),
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                icon: const Icon(Icons.person_add_outlined),
                label: const Text(
                  'Agregar conductor',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              )
            : null,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: _tabs.map((tab) {
            return BottomNavigationBarItem(
              icon: Icon(tab.icon),
              activeIcon: Icon(tab.activeIcon),
              label: tab.label,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    widget.company.name.isNotEmpty
                        ? widget.company.name[0].toUpperCase()
                        : 'E',
                    style: const TextStyle(
                      fontSize: 28,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.company.name,
                  style: const TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Empresa',
                  style: TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.people_outline,
              color: _currentIndex == 0 ? AppColors.primary : AppColors.textSecondary,
            ),
            title: Text(
              'Conductores',
              style: TextStyle(
                color: _currentIndex == 0 ? AppColors.primary : AppColors.textPrimary,
                fontWeight: _currentIndex == 0 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            tileColor: _currentIndex == 0 ? AppColors.primarySurface : null,
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 0);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.calendar_today_outlined,
              color: AppColors.textSecondary,
            ),
            title: const Text('Cronograma de Viajes'),
            subtitle: const Text('Ver todos los viajes programados'),
            onTap: () {
              Navigator.pop(context);
              context.push('/company/scheduled-trips', extra: {
                'companyId': widget.company.id,
                'companyName': widget.company.name,
              });
            },
          ),
          ListTile(
            leading: Icon(
              Icons.playlist_add_check_circle,
              color: _currentIndex == 1 ? AppColors.primary : AppColors.textSecondary,
            ),
            title: Text(
              'Aprobar Viajes',
              style: TextStyle(
                color: _currentIndex == 1 ? AppColors.primary : AppColors.textPrimary,
                fontWeight: _currentIndex == 1 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            subtitle: const Text('Revisar viajes de conductores'),
            tileColor: _currentIndex == 1 ? AppColors.primarySurface : null,
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 1);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.history,
              color: _currentIndex == 4 ? AppColors.primary : AppColors.textSecondary,
            ),
            title: Text(
              'Historial de Viajes',
              style: TextStyle(
                color: _currentIndex == 4 ? AppColors.primary : AppColors.textPrimary,
                fontWeight: _currentIndex == 4 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            subtitle: const Text('Ver viajes finalizados'),
            tileColor: _currentIndex == 4 ? AppColors.primarySurface : null,
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 4);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.mail_outline,
              color: _currentIndex == 2 ? AppColors.primary : AppColors.textSecondary,
            ),
            title: Text(
              'Invitaciones',
              style: TextStyle(
                color: _currentIndex == 2 ? AppColors.primary : AppColors.textPrimary,
                fontWeight: _currentIndex == 2 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            tileColor: _currentIndex == 2 ? AppColors.primarySurface : null,
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 2);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.business_outlined,
              color: _currentIndex == 3 ? AppColors.primary : AppColors.textSecondary,
            ),
            title: Text(
              'Perfil de Empresa',
              style: TextStyle(
                color: _currentIndex == 3 ? AppColors.primary : AppColors.textPrimary,
                fontWeight: _currentIndex == 3 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            tileColor: _currentIndex == 3 ? AppColors.primarySurface : null,
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 3);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Cerrar sesión', style: TextStyle(color: AppColors.error)),
            onTap: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
          ),
        ],
      ),
    );
  }
}

class _TabMeta {
  const _TabMeta({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}
