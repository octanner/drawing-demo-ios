//
//  SecondViewController.swift
//  drawing-demo
//
//  Created by Ben Norris on 4/24/19.
//  Copyright © 2019 O.C. Tanner. All rights reserved.
//
//  Innovation project section for Parker Rushton
//

import UIKit
import CoreData

class SecondViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private let coreDataManager = CoreDataManager.shared
    private var drawings = [Drawing]()
    
    lazy var fetchedResultsController: NSFetchedResultsController<Drawing> = {
        let fetchRequest = NSFetchRequest<Drawing>(entityName: Drawing.entityName)
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.shared.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        return frc
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        try? fetchedResultsController.performFetch()
    }

    func showImageViewer(for drawing: Drawing) {
        let storyboard = UIStoryboard(name: "ImageViewerViewController", bundle: nil)
        guard let imageViewerNav = storyboard.instantiateInitialViewController() as? UINavigationController, let imageViewer = imageViewerNav.viewControllers.first as? ImageViewerViewController else { return }
        modalPresentationStyle = .formSheet
        imageViewer.loadViewIfNeeded()
        imageViewer.image = drawing.image
        present(imageViewerNav, animated: true, completion: nil)
    }
    
}


// MARK: - NSFetchedResultsController

extension SecondViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        dump(sectionInfo)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        tableView.reloadData()
    }
    
}


// MARK: - TableView

extension SecondViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let firstSection = fetchedResultsController.sections?.first else { return 0 }
        return firstSection.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell", for: indexPath)
        let drawing = fetchedResultsController.object(at: indexPath)
        cell.imageView?.image = drawing.image
        cell.textLabel?.text = drawing.title ?? drawing.createdAtString
        if drawing.title != nil {
            cell.detailTextLabel?.text = drawing.createdAtString
        }
        return cell
    }
    
}

extension SecondViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let drawing = fetchedResultsController.object(at: indexPath)
        showImageViewer(for: drawing)
    }
    
}
