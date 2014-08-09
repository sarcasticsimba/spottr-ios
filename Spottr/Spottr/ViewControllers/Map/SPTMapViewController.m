//
//  SPTMapViewController.m
//  Spottr
//
//  Created by John Hammerlund on 8/8/14.
//  Copyright (c) 2014 Spottr. All rights reserved.
//

#import "SPTMapViewController.h"
#import <MapKit/MapKit.h>
#import <Parse/Parse.h>
#import "SPTCreateWorkoutController.h"
#import "SPTWorkout.h"
#import "SPTWorkoutAnnotation.h"

@interface SPTMapViewController () <MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation SPTMapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.mapView setDelegate:self];
    [self.mapView setUserTrackingMode:MKUserTrackingModeFollow];

    [self loadNearbyWorkouts];

    UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewWorkoutTapped:)];
    [self.navigationItem setRightBarButtonItem:addBarButtonItem];
}

- (void)loadNearbyWorkouts
{
    PFQuery *query = [PFQuery queryWithClassName:@"Workout"];
    __weak typeof(self) weakSelf = self;
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSMutableArray *mutableAnnotations = [NSMutableArray array];
            for (PFObject *object in objects) {
                SPTWorkout *workout = [SPTWorkout workoutWithParseObject:object];
                SPTWorkoutAnnotation *annotation = [SPTWorkoutAnnotation annotationWithWorkout:workout];
                [mutableAnnotations addObject:annotation];
                [weakSelf.mapView addAnnotation:annotation];
            }
//            [weakSelf.mapView addAnnotations:mutableAnnotations];
        });
    }];
}

- (void)addNewWorkoutTapped:(id)sender
{
    UIViewController *createWorkoutViewController = [SPTCreateWorkoutController new];
    UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(closePresentedViewController)];
    [createWorkoutViewController.navigationItem setLeftBarButtonItem:backBarButtonItem];
    // Embed in navigation controller for simple close behavior
    UINavigationController *destinationViewController = [[UINavigationController alloc] initWithRootViewController:createWorkoutViewController];
    [self presentViewController:destinationViewController animated:YES completion:nil];
}

- (void)closePresentedViewController
{
    // Hacky McHackenstein
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if (![annotation isKindOfClass:[SPTWorkoutAnnotation class]])
        return nil;

    static NSString * const kWorkoutAnnotationIdentifier = @"kWorkoutAnnotationIdentifier";
    MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:kWorkoutAnnotationIdentifier];
    if(annotationView){
        [annotationView setAnnotation:annotation];
    } else {
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kWorkoutAnnotationIdentifier];
    }
    [annotationView setImage:[UIImage imageNamed:@"SPTMapAnnotationIcon"]];
    [annotationView setCanShowCallout:YES];
    return annotationView;
}


- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 800, 800);
    [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
}

@end
