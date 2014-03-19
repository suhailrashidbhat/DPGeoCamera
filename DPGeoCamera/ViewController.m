//
//  ViewController.m
//  DPGeoCamera
//
//  Created by Suhail Rashid Bhat on 18/03/14.
//  Copyright (c) 2014 SuhailBhat. All rights reserved.
//

#import "ViewController.h"
#import "MobileCoreServices/UTCoreTypes.h"
#import "AssetsLibrary/AssetsLibrary.h"
#import <ImageIO/ImageIO.h>
#import <CoreLocation/CoreLocation.h>

@interface ViewController ()
@property (strong, nonatomic) IBOutlet UIButton *takeShotButton;
@property (strong, nonatomic) UIImage *pictureTaken;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)shotTakeTapped:(id)sender {
    // When no camera - simulator
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIAlertView *noCameraAlertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Device has no camera" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [noCameraAlertView show];
        
    } else {
        // open camera to take shot.
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        imagePicker.allowsEditing = YES;
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        // For Cellular network setting low quality high speed transfer.
        imagePicker.videoQuality = UIImagePickerControllerQualityTypeLow;
        imagePicker.mediaTypes = [NSArray arrayWithObjects:(NSString*)kUTTypeMovie, (NSString*)kUTTypeImage, nil];
        imagePicker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
        imagePicker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
        [self presentViewController:imagePicker animated:YES completion:NULL];
    }
}

#pragma mark - Image Picker Controller delegate methods

- (void)imagePickerController:(UIImagePickerController *)imagePicker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    //image
    if (info[UIImagePickerControllerEditedImage]) {
        UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
        NSData *imageData = UIImageJPEGRepresentation(chosenImage, 0.0); // maximum compression
        NSData *imageData1 = UIImageJPEGRepresentation(chosenImage, 0.5); // medium
        NSData *imageData2 = UIImageJPEGRepresentation(chosenImage, 1.0); // Highest
        
        NSLog(@"I1 %d, I2 %d, I3 %d", [imageData length], [imageData1 length], [imageData2 length]);
        
        
        self.pictureTaken = chosenImage;
        [self getImageWithMetaData:chosenImage];
        [imagePicker dismissViewControllerAnimated:YES completion:NULL];
        //Saves in library
        UIImageWriteToSavedPhotosAlbum(chosenImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    }
    
    //video
    // this snipets saves in library
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    NSURL *recordedVideoURL  = [info objectForKey:UIImagePickerControllerMediaURL];
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:recordedVideoURL]) {
        [library writeVideoAtPathToSavedPhotosAlbum:recordedVideoURL completionBlock:^(NSURL *assetURL, NSError *error) {
            
        }];
    }
    UISaveVideoAtPathToSavedPhotosAlbum(recordedVideoURL.absoluteString, self, @selector(video:didFinishSavingWithError:contextInfo:), NULL);
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

-(void)video:(NSString*)videoPath didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo {
    if (!videoPath && error) {
        NSLog(@"Error with :%@ ",error);
    }
    
}

-(void)image:(UIImage*)image didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo {
    if (!image && error) {
        NSLog(@"Error with :%@ ",error);
    }
    
}

-(NSMutableData *)getImageWithMetaData:(UIImage *)pImage
{
    NSData* pngData =  UIImagePNGRepresentation(pImage);
    
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)pngData, NULL);
    NSDictionary *metadata = (__bridge NSDictionary *) CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
    
    NSMutableDictionary *metadataAsMutable = [metadata mutableCopy];

    
    //For GPS Dictionary
    NSMutableDictionary *GPSDictionary = [[metadataAsMutable objectForKey:(NSString *)kCGImagePropertyGPSDictionary]mutableCopy];
    if(!GPSDictionary)
        GPSDictionary = [NSMutableDictionary dictionary];
    
    
    // Get current location
    double currentLatitude = 23.435;
    double currentLongitude = 12.213;
    CLLocation *location = [[CLLocation alloc] initWithLatitude:currentLatitude longitude:currentLongitude];
    
    [GPSDictionary setValue:[NSNumber numberWithDouble:currentLatitude] forKey:(NSString*)kCGImagePropertyGPSLatitude];
    [GPSDictionary setValue:[NSNumber numberWithDouble:currentLongitude] forKey:(NSString*)kCGImagePropertyGPSLongitude];
    
    NSString* ref;
    if (currentLatitude <0.0)
        ref = @"S";
    else
        ref =@"N";
    [GPSDictionary setValue:ref forKey:(NSString*)kCGImagePropertyGPSLatitudeRef];
    
    if (currentLongitude <0.0)
        ref = @"W";
    else
        ref =@"E";
    [GPSDictionary setValue:ref forKey:(NSString*)kCGImagePropertyGPSLongitudeRef];
    
    [GPSDictionary setValue:[NSNumber numberWithFloat:location.altitude] forKey:(NSString*)kCGImagePropertyGPSAltitude];
    
    //For EXIF Dictionary
    NSMutableDictionary *EXIFDictionary = [[metadataAsMutable objectForKey:(NSString *)kCGImagePropertyExifDictionary]mutableCopy];
    if(!EXIFDictionary)
        EXIFDictionary = [NSMutableDictionary dictionary];
    
    [EXIFDictionary setObject:[NSDate date] forKey:(NSString*)kCGImagePropertyExifDateTimeOriginal];
    [EXIFDictionary setObject:[NSDate date] forKey:(NSString*)kCGImagePropertyExifDateTimeDigitized];
    
    //add our modified EXIF data back into the image’s metadata
    [metadataAsMutable setObject:EXIFDictionary forKey:(NSString *)kCGImagePropertyExifDictionary];
    [metadataAsMutable setObject:GPSDictionary forKey:(NSString *)kCGImagePropertyGPSDictionary];
    
    CFStringRef UTI = CGImageSourceGetType(source);
    
    NSMutableData *dest_data = [NSMutableData data];
    CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)dest_data, UTI, 1, NULL);
    
    if(!destination)
        dest_data = [pngData mutableCopy];
    else
    {
        CGImageDestinationAddImageFromSource(destination, source, 0, (__bridge CFDictionaryRef) metadataAsMutable);
        BOOL success = CGImageDestinationFinalize(destination);
        if(!success)
            dest_data = [pngData mutableCopy];
    }
    
    if(destination)
        CFRelease(destination);
    
    CFRelease(source);
    
    return dest_data;
}

@end
