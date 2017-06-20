//
//  CalendarTableViewController.swift
//  Appt
//
//  Created by Agustin Mendoza Romo on 6/1/17.
//  Copyright © 2017 AgustinMendoza. All rights reserved.
//

import UIKit
import CoreData

class CalendarTableViewController: UITableViewController {

  private let segueNewApptTVC = "SegueNewApptTVC"
  
  private let segueApptDetail = "SegueApptDetail"
  
  let persistentContainer = CoreDataStore.instance.persistentContainer
  
  lazy var fetchedResultsController: NSFetchedResultsController<Appointment> = {
    let fetchRequest: NSFetchRequest<Appointment> = Appointment.fetchRequest()
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
    let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
    fetchedResultsController.delegate = self
    
    return fetchedResultsController
  }()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    persistentContainer.loadPersistentStores { (persistentStoreDescription, error) in
      
      
      do {
        try self.fetchedResultsController.performFetch()
        print("Appt Fetch Successful")
      } catch {
        let fetchError = error as NSError
        print("Unable to Perform Fetch Request")
        print("\(fetchError), \(fetchError.localizedDescription)")
      }
      
    }
    
    NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
  }
  
  
  // MARK: - Navigation
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == segueNewApptTVC {
      if let destinationNavigationViewController = segue.destination as? UINavigationController {
        // Configure View Controller
        let targetController = destinationNavigationViewController.topViewController as! NewApptTableViewController
        targetController.managedObjectContext = persistentContainer.viewContext
        print("context sent")
      }
    }
    
    if segue.identifier == segueApptDetail {
      if let indexPath = tableView.indexPathForSelectedRow {
        let appointment = fetchedResultsController.object(at: indexPath)
        let controller = (segue.destination as! ApptDetailTVC)
        controller.appointment = appointment
        
      }
    }
    
  }
  
  // MARK: - Notification Handling
  
  @objc func applicationDidEnterBackground(_ notification: Notification) {
    save()
  }
  
  func save () {
    do {
      try persistentContainer.viewContext.save()
      print("Saved Changes")
    } catch {
      print("Unable to Save Changes")
      print("\(error), \(error.localizedDescription)")
    }

  }

  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 80
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let appointments = fetchedResultsController.fetchedObjects else { return 0 }
    return appointments.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCell(withIdentifier: "AppointmentCell", for: indexPath) as! AppointmentCell
    
    let appointment = fetchedResultsController.object(at: indexPath)
    
    cell.nameLabel.text = appointment.patient?.fullName
    if let date = appointment.date {
      cell.dateLabel.text = dateFormatter(date: date)
    }
    cell.noteLabel.text = appointment.note
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      // Fetch Appointment
      let appointment = fetchedResultsController.object(at: indexPath)
      
      // Delete Appointment
      persistentContainer.viewContext.delete(appointment)
      save()
    }
  }
  
}

extension CalendarTableViewController: NSFetchedResultsControllerDelegate {
  
  func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    tableView.beginUpdates()
  }
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    tableView.endUpdates()
    
  }
  
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    switch (type) {
    case .insert:
      if let indexPath = newIndexPath {
        print("Appt Added")
        tableView.insertRows(at: [indexPath], with: .fade)
      }
      break;
    case .delete:
      if let indexPath = indexPath {
        tableView.deleteRows(at: [indexPath], with: .fade)
      }
      break;
    default:
      print("...")
    }
  }
  
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
    
  }
  
}

