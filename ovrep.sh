usage() {
echo "Just a simple script, that auto-generates OpenVAS pdf reports by getting as input a list of task names and a list of hosts."
echo "Usage: $0 <[-T <task|list_of_tasks> | -F <file]> " 1>&2;
echo "OPTIONS:"
echo "	-T <task1,task2,...>	Specify the name of the task or the UUID. Multiple tasks should be separated by comma"
echo "	-F <filepath>		Specify a list containing the names or UUID of tasks. Should be separated by an endline"
echo "	-A			Specifies that one report should be generated for all the hosts."
echo "	-H <filepath>		Specifies a file containing the list of hosts."
echo "	-O <directory_path>	Specifies a filepath for the directory in which to save the reports."
}

# This variable is 1 if '-A' option is given.
all_in_one=0

while getopts ":T:F:H:O:A" opt; do
	case $opt in
		T)
			IFS=',' read -ra tasks <<<"$OPTARG"
			;;
		F)
			tasks_file="$OPTARG"
			IFS=$'\r\n\t ' read -d '' -r -a tasks < $tasks_file
			;;
		A)
			all_in_one=1
			;;
		H)
			hosts_file="$OPTARG"
			;;
		O)
			output_directory="$OPTARG"
			;;
		\?)
			usage
			echo "Invalid option: -$OPTARG" >&2
			exit 1
			;;
		:)
			usage
			echo "Option -$OPTARG requires an argument." >&2
			exit 1
			;;
		*)
			usage
			;;
	esac
done

shift $((OPTIND-1))

if [ -z "${T}" ] && [ -z "${F}" ]; then
    usage
fi



for task in "${tasks[@]}" # Iterating through the tasks
do
	GREEN='\033[1;32m'
	RED='\033[0;31m'
	YELLOW='\033[1;33m'
	NC='\033[0m'
        echo -e "\n\n ${GREEN}Generating reports for task ${YELLOW}$task${NC}."
        echo -e "${RED}-------------------------------------${NC}"
	if [ "$(omp --get-tasks | grep -E "(^|\s)$task($|\s)" | wc -l)" -gt 1 ]; then
		echo -e "${RED} Too many tasks with the same name! Try using the UUID.${NC}"
		exit 1
	fi
	
	#Tests if the it a task name or a task UUID.
	if [[ $task =~ [a-z0-9]{8}\-[a-z0-9]{4}\-[a-z0-9]{4}\-[a-z0-9]{4}\-[a-z0-9]{12} ]]; then
		task_uuid=$task
		task_name="$(omp --get-tasks | grep -E "$task_uuid" | awk '{print $3}')"
	else
        	task_uuid="$(omp --get-tasks | grep -E "(^|\s)$task($|\s)" | tail -n 1 |  awk '{print $1}')"
		task_name=$task
	fi
        echo -e "Task ${YELLOW}$task_name${NC} uuid -> ${YELLOW}$task_uuid${NC}."

	# Checking to see if there are actually any reports for this task
	if [ "$(omp --get-tasks $task_uuid | wc -l)" -gt 1  ]; then
	        report_uuid="$(omp --get-tasks $task_uuid | tail -n 1 | awk '{print $1}')"
	else
		echo -e "${RED}There are no reports for this task.${NC}"
		exit 1
	fi
	
	# Saving the date of the report.	
        scan_date="$(omp --get-tasks $task_uuid | tail -n 1 | awk '{print $7}' | cut -d "T" -f1)" 
        echo -e "Report uuid -> ${YELLOW}$report_uuid${NC} executed on ${YELLOW}$scan_date${NC}."

	# Chosing the PDF format.
        format_uuid="$(omp --get-report-formats | grep -E "(^|\s)PDF($|\s)" | awk '{print $1}')"
        echo -e "PDF format uuid -> ${YELLOW}$format_uuid${NC}."

	# Creating a directory to hold the PDFs.
	if [ -z ${output_directory} ]; then
	        scan_dir="$(pwd)/${task_name}_${task_uuid}/Reports_$scan_date"
	else
		scan_dir="$output_directory/${task_name}_${task_uuid}/Reports_$scan_date"
	fi
        if [ ! -d "$scan_dir" ]; then
                echo -e "Direcotry ${YELLOW}$scan_dir${NC} does not exist. Creating it."
               	mkdir -p "$scan_dir"
        fi
	
	# Testing if there should be a report for every host, or one report per task, and then actually generating the reports.
	if [ -z ${hosts_file} ]; then
		list_file=$task_name.list
	else
		list_file=$hosts_file
	fi

	if [ $all_in_one -eq 0 ]; then
        	while IFS=$'\r\n\t ' read line
        	do
			if [ ! -z "${line}" ]; then
                		echo -e "Generating report for host ${YELLOW}$line${NC}."
                		# Generating the pdf report 
                		exec omp -X "<get_reports report_id=\"$report_uuid\" format_id=\"$format_uuid\" filter=\"host=$line autofp=0 apply_overrides=1 notes=1 overrides=1 result_hosts_only=1 first=1 rows=100 sort-reverse=severity levels=hml min_qod=70\"/>" | xmlstarlet sel -t -v 'get_reports_response/report/text()' | base64 -i -d > "$scan_dir/$line.pdf"
			fi
        	done <<<"$(cat $list_file)"
	else
		echo -e "Generating report for all hosts declared in task $task_name"
		# Generating the pdf report 
                exec omp -X "<get_reports report_id=\"$report_uuid\" format_id=\"$format_uuid\" filter=\"autofp=0 apply_overrides=1 notes=1 overrides=1 result_hosts_only=1 first=1 rows=100 sort-reverse=severity levels=hml min_qod=70\"/>" | xmlstarlet sel -t -v 'get_reports_response/report/text()' | base64 -i -d > "$scan_dir/all_hosts_$task_name.pdf"
	fi
done
