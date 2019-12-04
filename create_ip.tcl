set PROJECT_NAME aq_sigcap
set PART_NAME xc7z020clg400-1

create_project $PROJECT_NAME ./$PROJECT_NAME -part $PART_NAME -force

set FILES [list \
           ../$PROJECT_NAME/src/aq_sigcap.v \
           ../$PROJECT_NAME/src/aq_sigcap_ctl.v \
           ../$PROJECT_NAME/src/aq_sigcap_mem.v \
          ]

add_files -norecurse $FILES

ipx::package_project -root_dir ../$PROJECT_NAME -vendor aquaxis.com -library aquaxis -taxonomy /UserIP

set_property core_revision 1 [ipx::current_core]

ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
