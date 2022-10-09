import 'package:auto_route/auto_route.dart';
import 'package:fixit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fixit/features/auth/presentation/bloc/auth_state.dart';
import 'package:fixit/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../injection_container.dart';
import '../auth/presentation/bloc/auth_event.dart';

class HomePage extends StatelessWidget implements AutoRouteWrapper {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget wrappedRoute(BuildContext context) => BlocProvider<AuthBloc>(
        create: (BuildContext context) => sl<AuthBloc>(),
        child: this,
      );

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: _listener,
      builder: (BuildContext context, AuthState state) {
        return Center(
          child: TextButton(
            onPressed: () {
              BlocProvider.of<AuthBloc>(context)
                  .add(const LogoutPressed(fromOther: true));
            },
            child: const Text('Logout'),
          ),
        );
      },
    );
  }

  void _listener(BuildContext context, AuthState state) {
    if (state is LogoutSuccess) {
      context.router.navigate(const LoginRoute());
    }
  }
}
