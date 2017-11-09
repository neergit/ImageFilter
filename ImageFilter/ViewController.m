//
//  ViewController.m
//  ImageFilter
//
//  Created by Neeraj Chandra on 08/11/17.
//  Copyright © 2017 Neeraj Chandra. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()

@end

@implementation ViewController

NSArray *_pictureFilters;
NSNumber* _pictureFilterIterator;
UIImage* _originalImage;
UIImage* _currentImage;
UIImage* _filterImage;
CGPoint _startLocation;
BOOL _directionAssigned = NO;
enum direction {LEFT,RIGHT};
enum direction _direction;
BOOL _reassignIncomingImage = YES;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initializeFiltering];
}

-(void)initializeFiltering
{
    //create filters
    _pictureFilters = @[@"CISepiaTone",@"CIColorInvert",@"CIColorCube",@"CIFalseColor",@"CIPhotoEffectNoir"];
    _pictureFilterIterator = 0;
    
    _originalImage = _currentImageView.image;
    _currentImage = _currentImageView.image;
    
    UIPanGestureRecognizer* pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRecognized:)];
    [self.view addGestureRecognizer:pan];
}


-(void)swipeRecognized:(UIPanGestureRecognizer *)swipe
{
    CGFloat distance = 0;
    CGPoint stopLocation;
    if (swipe.state == UIGestureRecognizerStateBegan)
    {
        _directionAssigned = NO;
        _startLocation = [swipe locationInView:self.view];
    }else
    {
        stopLocation = [swipe locationInView:self.view];
        CGFloat dx = stopLocation.x - _startLocation.x;
        CGFloat dy = stopLocation.y - _startLocation.y;
        distance = sqrt(dx*dx + dy*dy);
    }
    
    if(swipe.state == UIGestureRecognizerStateEnded)
    {
        if(_direction == LEFT && (([UIScreen mainScreen].bounds.size.width - _startLocation.x) + distance) > [UIScreen mainScreen].bounds.size.width/2)
        {
            [self reassignCurrentImage];
        }else if(_direction == RIGHT && _startLocation.x + distance > [UIScreen mainScreen].bounds.size.width/2)
        {
            [self reassignCurrentImage];
        }else
        {
            //since no filter applied roll it back
            if(_direction == LEFT)
            {
                _pictureFilterIterator = [NSNumber numberWithInt:[_pictureFilterIterator intValue]-1];
            }else
            {
                _pictureFilterIterator = [NSNumber numberWithInt:[_pictureFilterIterator intValue]+1];
            }
        }
        [self clearIncomingImage];
        _reassignIncomingImage = YES;
        return;
    }
    
    CGPoint velocity = [swipe velocityInView:self.view];
    
    if(velocity.x > 0)//right
    {
        if(!_directionAssigned)
        {
            _directionAssigned = YES;
            _direction  = RIGHT;
        }
        if(_reassignIncomingImage && !_filterImage)
        {
            _reassignIncomingImage = false;
            [self reassignIncomingImageLeft:NO];
        }
    }
    else//left
    {
        if(!_directionAssigned)
        {
            _directionAssigned = YES;
            _direction  = LEFT;
        }
        if(_reassignIncomingImage && !_filterImage)
        {
            _reassignIncomingImage = false;
            [self reassignIncomingImageLeft:YES];
        }
    }
    
    if(_direction == LEFT)
    {
        if(stopLocation.x > _startLocation.x -5) //adjust to avoid snapping
        {
            distance = -distance;
        }
    }else
    {
        if(stopLocation.x < _startLocation.x +5) //adjust to avoid snapping
        {
            distance = -distance;
        }
    }
    
    [self slideIncomingImageDistance:distance];
}


-(void)slideIncomingImageDistance:(float)distance
{
    CGRect incomingImageCrop;
    if(_direction == LEFT) //start on the right side
    {
        incomingImageCrop = CGRectMake(_startLocation.x - distance,0, [UIScreen mainScreen].bounds.size.width - _startLocation.x + distance, [UIScreen mainScreen].bounds.size.height);
    }else//start on the left side
    {
        incomingImageCrop = CGRectMake(0,0, _startLocation.x + distance, [UIScreen mainScreen].bounds.size.height);
    }
    
    [self applyMask:incomingImageCrop];
}


-(void)reassignCurrentImage
{
    if(!_filterImage)//if you go fast this is null sometimes
    {
        [self reassignIncomingImageLeft:YES];
    }
    _currentImageView.image = _filterImage;
    self.view.frame = [[UIScreen mainScreen] bounds];
}

//left is forward right is back
-(void)reassignIncomingImageLeft:(BOOL)left
{
    if(left == YES)
    {
        _pictureFilterIterator = [NSNumber numberWithInt:[_pictureFilterIterator intValue]+1];
    }else
    {
        _pictureFilterIterator = [NSNumber numberWithInt:[_pictureFilterIterator intValue]-1];
    }
    
    NSNumber* arrayCount = [NSNumber numberWithInt:(int)_pictureFilters.count];
    
    if([_pictureFilterIterator integerValue]>=[arrayCount integerValue])
    {
        _pictureFilterIterator = 0;
    }
    if([_pictureFilterIterator integerValue]< 0)
    {
        _pictureFilterIterator = [NSNumber numberWithInt:(int)_pictureFilters.count-1];
    }
    
    CIImage* ciImage = [CIImage imageWithCGImage:_originalImage.CGImage];
    CIFilter* filter = [CIFilter filterWithName:_pictureFilters[[_pictureFilterIterator integerValue]] keysAndValues:kCIInputImageKey,ciImage, nil];
    _filterImage = [UIImage imageWithCIImage:[filter outputImage]];
    _filteredImageView.image = _filterImage;
    CGRect maskRect = CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height);

    [self applyMask:maskRect];
}


//apply mask to filter UIImageView
-(void)applyMask:(CGRect)maskRect
{
    // Create a mask layer and the frame to determine what will be visible in the view.
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    
    // Create a path with the rectangle in it.
    CGPathRef path = CGPathCreateWithRect(maskRect, NULL);
    
    // Set the path to the mask layer.
    maskLayer.path = path;
    
    // Release the path since it's not covered by ARC.
    CGPathRelease(path);
    
    // Set the mask of the view.
    _filteredImageView.layer.mask = maskLayer;
}


-(void)clearIncomingImage
{
    _filterImage = nil;
    _filteredImageView.image = nil;
    //mask current image view fully again
    [self applyMask:CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height)];

}

@end
