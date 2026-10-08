import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/features/home/cubit/home_cubit.dart';
import 'package:element_x/theme/rop_spacing.dart';
import 'package:element_x/theme/rop_theme.dart';
import 'package:element_x/widgets/room_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HomeSearchScreen extends StatefulWidget {
  const HomeSearchScreen({super.key});

  @override
  State<HomeSearchScreen> createState() => _HomeSearchScreenState();
}

class _HomeSearchScreenState extends State<HomeSearchScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('search'.tr())),
      body: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: RopSpacing.contentMaxWidth,
          ),
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(RopSpacing.md),
                    child: SearchBar(
                      controller: _query,
                      autoFocus: true,
                      hintText: 'search_hint'.tr(),
                      leading: const Icon(Icons.search),
                      onChanged: context.read<HomeCubit>().setQuery,
                    ),
                  ),
                  Expanded(
                    child: state.rooms.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(RopSpacing.xl),
                              child: Text(
                                _query.text.isEmpty
                                    ? 'search_prompt'.tr()
                                    : 'search_empty'.tr(),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: RopTheme.of(context).textSecondary,
                                    ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(
                              bottom: RopSpacing.lg,
                            ),
                            itemCount: state.rooms.length,
                            itemBuilder: (context, index) {
                              final room = state.rooms[index];
                              return RoomTile(
                                room: room,
                                onTap: () =>
                                    context.push(RoutePaths.room(room.id)),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
