//
//  WorkflowOverviewView.swift

struct WorkflowOverviewView: View {
    @ObservedObject var viewModel: TransferProcessViewModel
    
    var body: some View {
        List(viewModel.transferProcesses) { process in
            Text(process.title)
        }
    }
}
