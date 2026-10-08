import 'package:element_x/features/invitepeople/cubit/invitepeople_cubit.dart';
import 'package:element_x/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InvitePeopleScreen extends StatefulWidget {
  const InvitePeopleScreen({super.key});

  @override
  State<InvitePeopleScreen> createState() => _InvitePeopleScreenState();
}

class _InvitePeopleScreenState extends State<InvitePeopleScreen> {
  final _userId = TextEditingController();

  @override
  void dispose() {
    _userId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invite people')),
      body: BlocBuilder<InvitePeopleCubit, InvitePeopleState>(
        builder: (context, state) {
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _userId,
                  decoration: const InputDecoration(
                    labelText: 'Matrix ID',
                    hintText: '@name:server',
                  ),
                  onSubmitted: (value) {
                    context.read<InvitePeopleCubit>().invite(value.trim());
                    _userId.clear();
                  },
                ),
              ),
              if (state.people.isEmpty)
                const ListTile(
                  title: Text('Or pick someone you already know.'),
                ),
              for (final person in state.people)
                ListTile(
                  leading: UserAvatar(label: person.displayName),
                  title: Text(person.displayName),
                  subtitle: Text(person.id),
                  trailing: state.invited.contains(person.id)
                      ? const Text('Invited')
                      : FilledButton(
                          onPressed: () => context
                              .read<InvitePeopleCubit>()
                              .invite(person.id),
                          child: const Text('Invite'),
                        ),
                ),
            ],
          );
        },
      ),
    );
  }
}
