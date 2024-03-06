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
        case loaded = "home_screen_loaded"
        case appear = "home_screen_appear"
        case disAppear = "home_screen_disappear"
        case tapPhotos = "home_screen_tap_photos"
        case tapSmartCleaning = "home_screen_tap_smart_cleaning"
        case tapCalendar = "home_screen_tap_calendar"
        case tapContacts = "home_screen_tap_contacts"
        case storageInfo = "home_screen_storage_info"
    }
    
    enum CompressorScreen: String{
        case loaded = "compressor_screen_loaded"
        case appear = "compressor_screen_appear"
        case disappear = "compressor_screen_disappear"
        case videoCount = "compressor_screen_video_count"
        case loadingStatus = "compressor_screen_loading_status"
    }
    
    
    enum CompressQualityScreen: String{
        case loaded = "compressor_quality_screen_loaded"
        case appear = "compressor_quality_screen_appear"
        case disappear = "compressor_quality_screen_disappear"
        case compressButtonPressed = "compressor_quality_screen_compress__pressed"
        case keepOriginalButtonPressed = "compressor_quality_screen_keep_original_pressed"
        case deleteOriginalButtonPressed = "compressor_quality_screen_delete_original_pressed"
        case compressStatus = "compressor_quality_screen_compress_Status"
        case savePhotoToGalleryStatus = "compressor_quality_screen_save_photo_status"
    }
    
    enum MediaScreen: String{
        case loaded = "media_screen_loaded"
        case appear = "media_screen_appear"
        case disappear = "media_screen_disappear"
        case fileToDelete = "media_screen_file_to_delete"
        case duplicatePhotosCount = "media_screen_duplicate_photos_count"
        case similarPhotosCount = "media_screen_similar_photos_count"
        case otherPhotosCount = "media_screen_other_photos_count"
        case duplicateScreenshotCount = "media_screen_duplicate_screenshot_count"
        case similarScreenshotCount = "media_screen_similar_screenshot_count"
        case otherScreenshotCount = "media_screen_other_screenshot_count"
    }
    
    enum CalendarScreen: String{
        case loaded = "calendar_screen_loaded"
        case appear = "calendar_screen_appear"
        case disappear = "calendar_screen_disappear"
        case deleteButtonPressed = "calendar_screen_delete_botton_pressed"
        case currentSegment = "calendar_screen_current_segment"
        case eventCount = "calendar_screen_event_count"
        case reminderCount = "calendar_screen_reminder_count"
        case calendarAuthorization = "calendar_screen_calendar_authorization_status"
        case reminderAuthorization = "calendar_screen_reminder_authorization_status"
        case goToSettingButtonPressed = "calendar_screen_go_to_setting_button_pressed"
        case eventDeleted = "calendar_screen_event_deleted"
        case reminderDeleted = "calendar_screen_reminder_deleted"
        case reminderDeleteCancel = "calender_screen_reminder_delete_cancel"
        case eventDeleteCancel = "calender_screen_event_delete_cancel"
    }
    
    enum DuplicatePhotosScreen: String{
        case loaded = "duplicate_photos_screen_loaded"
        case appear = "duplicate_photos_screen_appear"
        case disappear = "duplicate_photos_screen_disappear"
        case count = "duplicate_photos_screen_count"
        case deleteButtonPressed = "duplicate_photos_screen_delete_pressed"
        case deletedPhotos = "duplicate_photos_screen_photos_deleted"
        
    }
    
    enum SimilarPhotosScreen: String{
        case loaded = "similar_photos_screen_loaded"
        case appear = "similar_photos_screen_appear"
        case disappear = "similar_photos_screen_disappear"
        case count = "similar_photos_screen_count"
        case deleteButtonPressed = "similar_photos_screen_delete_pressed"
        case deletedPhotos = "similar_photos_screen_photos_deleted"
    }
    
    enum DuplicateScreenshotScreen: String{
         case loaded = "duplicate_screenshot_screen_loaded"
        case appear = "duplicate_screenshot_screen_appear"
        case disappear = "duplicate_screenshot_screen_disappear"
        case count = "duplicate_screenshot_screen_count"
        case deleteButtonPressed = "duplicate_screenshot_screen_delete_pressed"
        case deletedScreenshot = "duplicate_screenshot_screen_photos_deleted"
    }
    
    enum SimilarScreenshotScreen: String{
        case loaded = "similar_screenshot_screen_loaded"
        case appear = "similar_screenshot_screen_appear"
        case disappear = "similar_screenshot_screen_disappear"
        case count = "similar_screenshot_screen_count"
        case deleteButtonPressed = "similar_screenshot_screen_delete_pressed"
        case deletedScreenshot = "similar_screenshot_screen_photos_deleted"
    }
    
    enum OtherPhotosScreen: String{
        case loaded = "other_photos_screen_loaded"
        case appear = "other_photos_screen_appear"
        case disappear = "other_photos_screen_disappear"
        case count = "other_photos_screen_count"
        case deleteButtonPressed = "other_photos_screen_delete_pressed"
        case deletedPhotos = "other_photos_screen_photos_deleted"
    }
    
    enum OtherScreenshotScreen: String{
        case loaded = "other_screenshot_screen_loaded"
        case appear = "other_screenshot_screen_appear"
        case disappear = "other_screenshot_screen_disappear"
        case count = "other_screenshot_screen_count"
        case deleteButtonPressed = "other_screenshot_screen_delete_pressed"
        case deletedScreenshot = "other_screenshot_screen_photos_deleted"
    }
    
    enum GalleryManager: String{
        case fetchStatus = "fetching_status"
    }
    
}


func logEvent(_ event:String, parameter: [String: Any]?){
    Analytics.logEvent(event, parameters: parameter)
}

func logError(error: NSError){
    logEvent("error_found", parameter: ["error": error, "localized": error.localizedDescription, "userInfo": error.userInfo])
    print(error)
}

func logErrorString(errorString: String){
    logEvent("error_string_found", parameter: ["error": errorString])
    print(errorString)
}


