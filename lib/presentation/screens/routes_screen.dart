import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shuttletrack/presentation/bloc/route/route_bloc.dart';
import 'package:shuttletrack/presentation/widgets/route_card.dart';

class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: const Text('Routes'),
      ),
      body: BlocBuilder<RouteBloc, RouteState>(
        builder: (context, state) {
          if (state is RouteLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is RouteError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is RouteLoaded) {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.routes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final route = state.routes[index];
                return RouteCard(
                  route: route,
                  isSelected: state.selectedRoute?.id == route.id,
                  onTap: () {
                    context.read<RouteBloc>().add(SelectRoute(route.id));
                  },
                );
              },
            );
          }
          if (state is RouteEmpty) {
            return const Center(child: Text('No routes available'));
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
