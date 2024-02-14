//
//  EventsHandler.swift
//  CleanerApp
//
//  Created by Manu on 13/02/24.
//

import Foundation
import Firebase


enum Event: String{
    case appLaunched = "app_events_app_launched"
    case appEnterBackground = "app_events_app_enter_background"
    case appEnterForeground = "app_events_app_enter_foreground"
    case appTerminated = "app_events_app_terminated"
    
    enum HomeScreen: String{
        case loaded = "app_events_home_screen_loaded"
        case appear = "app_events_home_screen_appear"
        case disAppear = "app_events_home_screen_disappear"
        case tapPhotos = "app_events_home_screen_tap_photos"
        case tapSmartCleaning = "app_events_home_screen_tap_smart_cleaning"
        case tapCalendar = "app_events_home_screen_tap_calendar"
        case tapContacts = "app_events_home_screen_tap_contacts"
    }
    
    enum CompressorScreen: String{
        case loaded = "app_events_compressor_screen_loaded"
        case appear = "app_events_compressor_screen_appear"
        case disappear = "app_events_compressor_screen_disappear"
        case videoCount = "app_events_compressor_screen_video_count"
        case loadingStatus = "app_events_compressor_screen_loading_status"
    }
    
    
    enum CompressQualityScreen: String{
        case loaded = "app_events_compressor_quality_screen_loaded"
        case appear = "app_events_compressor_quality_screen_appear"
        case disappear = "app_events_compressor_quality_screen_disappear"
        case compressButtonPressed = "app_events_compressor_quality_screen_compress__pressed"
        case keepOriginalButtonPressed = "app_events_compressor_quality_screen_keep_original_pressed"
        case deleteOriginalButtonPressed = "app_events_compressor_quality_screen_delete_original_pressed"
        case compressStatus = "app_events_compressor_quality_screen_compress_Status"
        case savePhotoToGalleryStatus = "app_events_compressor_quality_screen_save_photo_status"
    }
    
    enum MediaScreen: String{
        case loaded = "app_events_media_screen_loaded"
        case appear = "app_events_media_screen_appear"
        case disappear = "app_events_media_screen_disappear"
        case fileToDelete = "app_events_media_screen_file_to_delete"
        case duplicatePhotosCount = "app_events_media_screen_duplicate_photos_count"
        case similarPhotosCount = "app_events_media_screen_similar_photos_count"
        case otherPhotosCount = "app_events_media_screen_other_photos_count"
        case duplicateScreenshotCount = "app_events_media_screen_duplicate_screenshot_count"
        case similarScreenshotCount = "app_events_media_screen_similar_screenshot_count"
        case otherScreenshotCount = "app_events_media_screen_other_screenshot_count"
    }
    
    enum CalendarScreen: String{
        case loaded = "app_events_calendar_screen_loaded"
        case appear = "app_events_calendar_screen_appear"
        case disappear = "app_events_calendar_screen_disappear"
        case eventsDeleteButtonPressed = "app_events_calendar_screen_events_delete_botton_pressed"
        case reminderDeleteButtonPressed = "app_events_calendar_screen_reminder_delete_botton_pressed"
        case currentSegment = "app_events_calendar_screen_current_segment"
        case eventsCount = "app_events_calendar_screen_events_count"
        case reminderCount = "app_events_calendar_screen_reminder_count"
        case calendarAuthorization = "app_events_calendar_screen_calendar_authorization_status"
        case reminderAuthorization = "app_events_calendar_screen_reminder_authorization_status"
        case goToSettingButtonPressed = "app_events_calendar_screen_go_to_setting_button_pressed"
    }
    
    enum DuplicatePhotosScreen: String{
        case loaded = "app_events_duplicate_photos_screen_loaded"
        case appear = "app_events_duplicate_photos_screen_appear"
        case disappear = "app_events_duplicate_photos_screen_disappear"
        case count = "app_events_duplicate_photos_screen_count"
        case deleteButtonPressed = "app_events_duplicate_photos_screen_delete_pressed"
        
    }
    
    enum SimilarPhotosScreen: String{
        case loaded = "app_events_similar_photos_screen_loaded"
        case appear = "app_events_similar_photos_screen_appear"
        case disappear = "app_events_similar_photos_screen_disappear"
        case count = "app_events_similar_photos_screen_count"
        case deleteButtonPressed = "app_events_similar_photos_screen_delete_pressed"
    }
    
    enum DuplicateScreenshotScreen: String{
         case loaded = "app_events_duplicate_screenshot_screen_loaded"
        case appear = "app_events_duplicate_screenshot_screen_appear"
        case disappear = "app_events_duplicate_screenshot_screen_disappear"
        case count = "app_events_duplicate_screenshot_screen_count"
        case deleteButtonPressed = "app_events_duplicate_screenshot_screen_delete_pressed"
    }
    
    enum SimilarScreenshotScreen: String{
        case loaded = "app_events_similar_screenshot_screen_loaded"
        case appear = "app_events_similar_screenshot_screen_appear"
        case disappear = "app_events_similar_screenshot_screen_disappear"
        case count = "app_events_similar_screenshot_screen_count"
        case deleteButtonPressed = "app_events_similar_screenshot_screen_delete_pressed"
    }
    
    enum OtherPhotosScreen: String{
        case loaded = "app_events_other_photos_screen_loaded"
        case appear = "app_events_other_photos_screen_appear"
        case disappear = "app_events_other_photos_screen_disappear"
        case count = "app_events_other_photos_screen_count"
        case deleteButtonPressed = "app_events_other_photos_screen_delete_pressed"
    }
    
    enum OtherScreenshotScreen: String{
        case loaded = "app_events_other_screenshot_screen_loaded"
        case appear = "app_events_other_screenshot_screen_appear"
        case disappear = "app_events_other_screenshot_screen_disappear"
        case count = "app_events_other_screenshot_screen_count"
        case deleteButtonPressed = "app_events_other_screenshot_screen_delete_pressed"
    }
    
    enum GalleryManager: String{
        case fetchStatus = "app_events_fetching_status"
    }
}

func logEvent(_ event:String, parameter: [String: Any]?){
    Analytics.logEvent(event, parameters: parameter)
}


