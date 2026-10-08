import 'package:element_x/features/viewfolder/cubit/viewfolder_state.dart';
export 'package:element_x/features/viewfolder/cubit/viewfolder_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/features/viewfolder/repo/viewfolder_repo.dart';

class ViewFolderCubit extends Cubit<ViewFolderState> {
  ViewFolderCubit(ViewFolderRepo repo, String roomId)
    : super(ViewFolderState(files: repo.files(roomId)));
}
