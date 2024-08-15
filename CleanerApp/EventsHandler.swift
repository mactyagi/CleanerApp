//
//  EventsHandler.swift
//  CleanerApp
//
//  Created by Manu on 13/02/24.
//

import Foundation
import Firebase

enum Event: String{
    case appLaunched = "app_launched"
    case appEnterBackground = "app_enter_background"
    case appEnterForeground = "app_enter_foreground"
    case appTerminated = "app_terminated"
    
    enum HomeScreen: String{
//        hs -> Home Screen
        case loaded = "hs_loaded"
        case appear = "hs_appear"
        case disAppear = "hs_disappear"
        case tapPhotos = "hs_tap_photos"
        case tapSmartCleaning = "hs_tap_smart_cleaning"
        case tapCalendar = "hs_tap_calendar"
        case tapContacts = "hs_tap_contacts"
        case storageInfo = "hs_storage_info"
    }
    
    enum CompressorScreen: String{
        // cps -> Compress Screen
        case loaded = "cps_loaded"
        case appear = "cps_appear"
        case disappear = "cps_disappear"
        case videoCount = "cps_video_count"
        case loadingStatus = "cps_loading_status"
    }
    
    
    enum CompressQualityScreen: String{
        //cpqs -> Compression Quality Screen
        case loaded = "cpqs_loaded"
        case appear = "cpqs_appear"
        case disappear = "cpqs_disappear"
        case compressButtonPressed = "cpqs_compress_pressed"
        case keepOriginalButtonPressed = "cpqs_keep_original_pressed"
        case deleteOriginalButtonPressed = "cpqs_delete_original_pressed"
        case compressStatus = "ccpqs_compress_Status"
        case savePhotoToGalleryStatus = "cpqs_save_photo_status"
    }
    
    enum MediaScreen: String{
//        ms -> media screen
        case loaded = "ms_loaded"
        case appear = "ms_appear"
        case disappear = "ms_disappear"
        case fileToDelete = "ms_file_to_delete"
        case duplicatePhotosCount = "ms_duplicate_photos_count"
        case similarPhotosCount = "ms_similar_photos_count"
        case otherPhotosCount = "ms_other_photos_count"
        case duplicateScreenshotCount = "ms_duplicate_screenshot_count"
        case similarScreenshotCount = "ms_similar_screenshot_count"
        case otherScreenshotCount = "ms_other_screenshot_count"
    }
    
    enum CalendarScreen: String{
        //cs -> calendar Screen
        case loaded = "cs_loaded"
        case appear = "cs_appear"
        case disappear = "cs_disappear"
        case deleteButtonPressed = "cs_delete_botton_pressed"
        case currentSegment = "cs_current_segment"
        case eventCount = "cs_event_count"
        case reminderCount = "cs_reminder_count"
        case calendarAuthorization = "cs_calendar_auth_status"
        case reminderAuthorization = "cs_reminder_auth_status"
        case goToSettingButtonPressed = "cs_go_to_setting_pressed"
        case eventDeleted = "cs_event_deleted"
        case reminderDeleted = "cs_reminder_deleted"
        case reminderDeleteCancel = "cs_reminder_delete_cancel"
        case eventDeleteCancel = "cs_event_delete_cancel"
    }
    
    enum DuplicatePhotosScreen: String{
//        dps -> Duplicate Photos Screen
        case loaded = "dps_loaded"
        case appear = "dps_appear"
        case disappear = "dps_disappear"
        case count = "dps_count"
        case deleteButtonPressed = "dps_delete_pressed"
        case deletedPhotos = "dps_photos_deleted"

    }
    
    enum SimilarPhotosScreen: String{
//        sps -> Similar Photos Screen
        case loaded = "sps_loaded"
        case appear = "sps_appear"
        case disappear = "sps_disappear"
        case count = "sps_count"
        case deleteButtonPressed = "sps_delete_pressed"
        case deletedPhotos = "sps_photos_deleted"
    }
    
    enum DuplicateScreenshotScreen: String{
//        dss -> Duplicate Screenshot Screen
         case loaded = "dss_loaded"
        case appear = "dss_appear"
        case disappear = "dss_disappear"
        case count = "dss_count"
        case deleteButtonPressed = "dss_delete_pressed"
        case deletedScreenshot = "dss_photos_deleted"
    }
    
    enum SimilarScreenshotScreen: String{
//        sss -> Similar Screenshot Screen
        case loaded = "sss_loaded"
        case appear = "sss_appear"
        case disappear = "sss_disappear"
        case count = "sss_count"
        case deleteButtonPressed = "sss_delete_pressed"
        case deletedScreenshot = "sss_photos_deleted"
    }
    
    enum OtherPhotosScreen: String{
//        ops -> Other Photos Screen
        case loaded = "ops_loaded"
        case appear = "ops_appear"
        case disappear = "ops_disappear"
        case count = "ops_count"
        case deleteButtonPressed = "ops_delete_pressed"
        case deletedPhotos = "ops_photos_deleted"
    }
    
    enum OtherScreenshotScreen: String{
//        oss -> Other Screenshot Screen
        case loaded = "oss_loaded"
        case appear = "oss_appear"
        case disappear = "oss_disappear"
        case count = "oss_count"
        case deleteButtonPressed = "oss_delete_pressed"
        case deletedScreenshot = "oss_photos_deleted"
    }

    enum OrganizeContactScreen: String {
        case appear = "ocs_appear"
        case disappear = "ocs_disappear"
        case incompleteCount = "ocs_incomplete_count"
        case allContactCount = "ocs_all_contact_count"
        case duplicateContactCount = "ocs_duplicate_contact_count"
    }

    enum AllContactScreen: String {
        case appear = "acs_appear" // done
        case disAppear = "acs_disappear" // done
        case allContactCount = "acs_count" // done
        case select = "acs_select"  // done
        case selectAll = "acs_select_all" // done
        case deselectAll = "acs_deselect_all" //done
        case selectedCount = "acs_selected_count" // done
        case search = "acs_search" // done
        case deletePressed = "acs_delete_pressed"  //done
        case deleteConfirmed = "acs_delete_confirmed" // done
        case deleteCancel = "acs_delete_cancel" // done
    }

    enum IncompleteContactScreen: String {
        case appear = "ics_appear" // done
        case disappear = "ics_disappear" // done
        case count = "ics_count" // done
        case selectAll = "ics_select_all" // done
        case deselectAll = "ics_deselect_all" // done
        case selectedCount = "ics_selected_count" // done
        case deleteButtonPressed = "ics_delete_pressed" // done
        case deleteConfirmed = "ics_delete_confirmed" // done
        case deleteCancel = "ics_delete_cancel" // done
    }

    enum DuplicateContactScreen: String {
        case appear = "dcs_appear" // done
        case disappear = "dcs_disappear" // done
        case mergePressed = "dcs_merged_pressed" // done
        case mergeConfirmed = "dcs_merge_confirmed" // done
        case mergeCancel = "dcs_merge_cancel" // done
        case totalMergeItems = "dcs_total_items" // done

    }

    enum GalleryManager: String{
        case fetchStatus = "fetching_status"
    }
    
}


func logEvent(_ event:String, parameter: [String: Any]?){
    Analytics.logEvent(event, parameters: parameter)
}

func logError(error: NSError){
    logEvent("cleaner_error_found", parameter: ["error": error, "localized": error.localizedDescription, "userInfo": error.userInfo])
    print(error)
}

func logErrorString(errorString: String){
    logEvent("cleaner_error_string_found", parameter: ["error": errorString])
    print(errorString)
}


