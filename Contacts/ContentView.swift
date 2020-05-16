//
//  ContentView.swift
//  Contacts
//
//  Created by mac on 5/14/20.
//  Copyright © 2020 mac. All rights reserved.
//


import SwiftUI
import LBTATools

enum SectionType {
    case ceo, peasants
}

class Contact: NSObject {
    let name: String
    var isFavorite = false
    
    init(name: String){
        self.name = name
    }
}

class ContactViewModel: ObservableObject {
    @Published var name = ""
    @Published var isFavorite = false
}

struct ContactRowView: View {
    
    @ObservedObject var viewModel: ContactViewModel
    
    var body: some View {
        HStack(spacing : 16) {
            Image(systemName: "person.fill")
                .font(.system(size: 34))
            Text(viewModel.name)
            Spacer()
            Image(systemName: viewModel.isFavorite ? "star.fill" : "star")
            .font(.system(size: 24))

        }.padding(20)
    }
}


class ContactCell: UITableViewCell {
    
    let viewModel = ContactViewModel()
    
    lazy var row = ContactRowView(viewModel: viewModel)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // setup my SwiftUI view somehow....
        let hostingController = UIHostingController(rootView: row)
        addSubview(hostingController.view)
        hostingController.view.fillSuperview()
        
        viewModel.name = "SOMETHING COMPLETELY NEW"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ContactSource: UITableViewDiffableDataSource<SectionType, Contact>{
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}

class DiffableTableViewController: UITableViewController {
    
    //UITableViewDiffableDataSource
    
    lazy var source: ContactSource = .init(tableView: self.tableView) { (_, indexPath, contact) -> UITableViewCell? in
        
        let cell = ContactCell(style: .default, reuseIdentifier: nil)
//        cell.textLabel?.text = contact.name
        cell.viewModel.name = contact.name
        cell.viewModel.isFavorite = contact.isFavorite
        return cell
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deletAction = UIContextualAction(style: .destructive, title: "Delete"){
            (action , view , completion) in
            completion(true)
            
            
            var snapshot = self.source.snapshot()
            
            guard let contact = self.source.itemIdentifier(for: indexPath)
                else{return}
            snapshot.deleteItems([contact])
            
            self.source.apply(snapshot)
        
            
        }


        let favoriteAction = UIContextualAction(style: .normal, title: "Favorite"){
            (_, _, completion ) in
            completion (true)
        
        
        var snapshot = self.source.snapshot()
                   
                   guard var contact = self.source.itemIdentifier(for: indexPath)
                       else { return }
            contact.isFavorite.toggle()
                   snapshot.reloadItems([contact])
                   
                   self.source.apply(snapshot)

        }






        return .init(actions: [deletAction, favoriteAction ])
    }
        
    
    
    private func setupSource() {
        var snapshot = source.snapshot()
        snapshot.appendSections([.ceo, .peasants])
        snapshot.appendItems([
            .init(name: "Elon Musk"),
            .init(name: "Tim Cook"),
            .init(name: "WHATEVRE")
        ], toSection: .ceo)
        
        snapshot.appendItems([.init(name: "Bill Gates")], toSection: .peasants)
        
        source.apply(snapshot)
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.text = section == 0 ? "CEO" : "Peasants"
        return label
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Contacts"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        navigationItem.rightBarButtonItem = .init(title: "Add Contacts", style: .plain, target: self, action: #selector(handleAdd))
        
        setupSource()
    }
    @objc private func handleAdd(){
        let formView = ContacFormView {
            (name, sectionType)  in
            self.dismiss(animated: true)
            
            var snapshot = self.source.snapshot()
             snapshot.appendItems([.init(name: name)], toSection: sectionType)
            self.source.apply(snapshot)
        }
        let hostingController = UIHostingController(rootView: formView)
        present(hostingController,animated: true)
        
        

//
    }
}

struct ContacFormView:View {
    
    var didiContact: (String,SectionType)-> () = {_,_ in}
    @State private var name = ""
    
    @State private var sectiontype = SectionType.ceo

    var body: some View{
        VStack(spacing: 20){
            TextField("Name", text: $name)
            
            Picker(selection: $sectiontype, label: Text("abc")){
                Text("CEO").tag(SectionType.ceo)
                Text("Peasants").tag(SectionType.peasants)

            }.pickerStyle(SegmentedPickerStyle())
            
            
            
            Button(action: {
                self.didiContact(self.name,self.sectiontype )
            }, label: {
                HStack{
                    Spacer()
                    Text("Add").foregroundColor(.white)
                    Spacer()
                }.padding().background(Color.blue)
                .cornerRadius(5)
            }
            )
            Spacer()
        }.padding()
    }
}

struct DiffableContainer: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        UINavigationController(rootViewController: DiffableTableViewController(style: .insetGrouped))
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
    typealias UIViewControllerType = UIViewController
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        DiffableContainer()
    }
}


struct ContentView: View {
    var body: some View {
        DiffableContainer()
    }
}
