//
//  ViewController.m
//  DHImageComponentFilterExample
//
//  Created by 黄鸿森 on 2017/7/29.
//  Copyright © 2017年 Huang Hongsen. All rights reserved.
//

#import "ViewController.h"
#import <GPUImage/GPUImage.h>
#import "DHComponentFilterPickerCollectionViewController.h"
#import <DHImageKit/DHImageKit.h>
#import "DHSliderInputPanel.h"
#import "DHColorPickerCollectionViewController.h"
#import "DHIFFilterPickerCollectionViewController.h"
#import "DHTiltTypeChoosePanel.h"

@interface ViewController ()<DHComponentFilterPickerCollectionViewControllerDelegate, DHSliderInputPanelDelegate, DHColorPickerCollectionViewControllerDelegate, DHTiltTypeChoosePanelDelegate,DHIFFilterPickerCollectionViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet GPUImageView *renderTarget;
@property (nonatomic, strong) DHComponentFilterPickerCollectionViewController *editorPicker;
@property (nonatomic, strong) DHIFFilterPickerCollectionViewController *filterPicker;

@property (nonatomic, weak) UIView *editPanel;
@property (nonatomic, strong) DHColorPickerCollectionViewController *colorPicker;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.filterPicker = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"DHIFFilterPickerCollectionViewController"];
    self.filterPicker.delegate = self;
    
    self.editorPicker = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"DHComponentFilterPickerCollectionViewController"];
    self.editorPicker.delegate = self;
    
    [self showFilters:nil];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.renderTarget addGestureRecognizer:pan];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"sample_kuru" ofType:@"jpg"];
    
    [[DHImageEditor sharedEditor] initiateEditorWithImageURL:[NSURL fileURLWithPath:filePath] renderTarget:self.renderTarget completion:nil];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[DHImageEditor sharedEditor] showOriginalImage];
}

- (void) viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.editorPicker.view.frame = self.containerView.bounds;
    self.filterPicker.view.frame = self.containerView.bounds;
}

#pragma mark - DHComponentFilterPickerCollectionViewControllerDelegate
- (void) compoenentFilterPicker:(DHComponentFilterPickerCollectionViewController *)picker didPickComponentType:(DHImageEditComponent)component
{
    [[DHImageEditor sharedEditor] startProcessingComponent:component];
    [self showValueInputPanelForComponent:component];
}

- (void) showValueInputPanelForComponent:(DHImageEditComponent)component
{
    if (component == DHImageEditComponentColor) {
        self.colorPicker = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"DHColorPickerCollectionViewController"];
        self.colorPicker.delegate = self;
        self.colorPicker.view.alpha = 0.01;
        [self addChildViewController:self.colorPicker toParentViewController:self inContainerView:self.containerView];
        self.colorPicker.view.frame = self.containerView.bounds;
        [UIView animateWithDuration:0.2 animations:^{
            self.colorPicker.view.alpha = 1.f;
            self.editorPicker.view.alpha = 0.01;
        }];
    } else if (component == DHImageEditComponentTiltShift){
        DHTiltTypeChoosePanel *typeChoosingPanel = [[DHTiltTypeChoosePanel alloc] initWithFrame:self.containerView.bounds];
        self.editPanel = typeChoosingPanel;
        typeChoosingPanel.delegate = self;
        [self.containerView addSubview:typeChoosingPanel];
        [UIView animateWithDuration:0.2 animations:^{
            typeChoosingPanel.alpha = 1.f;
            self.editorPicker.view.alpha = 0.01;
        }];
    }else {
        DHImageEditorValues values = [DHImageHelper valuesforComponent:component];
        DHSliderInputPanel *inputPanel = [[DHSliderInputPanel alloc] initWithFrame:self.containerView.bounds];
        inputPanel.delegate = self;
        inputPanel.alpha = 0.01;
        [inputPanel setMinValue:values.minValue];
        [inputPanel setMaxValue:values.maxValue];
        NSDictionary *initialParameters = [[DHImageEditor sharedEditor] initialParameters];
        CGFloat inputValue = [[[initialParameters allValues] lastObject] doubleValue];
        [inputPanel setInitialValue:inputValue];
        NSLog(@"----------inputValue = %g", inputValue);
        self.editPanel = inputPanel;
        [self.containerView addSubview:inputPanel];
        [UIView animateWithDuration:0.2 animations:^{
            inputPanel.alpha = 1.f;
            self.editorPicker.view.alpha = 0.01;
        }];
    }
}

- (void) hideValieInputPanel
{
    [UIView animateWithDuration:0.2 animations:^{
        self.editPanel.alpha = 0.01;
        self.editorPicker.view.alpha = 1.f;
    } completion:^(BOOL finished) {
        [self.editPanel removeFromSuperview];
    }];
}

#pragma mark - Event handling
- (void) handlePan:(UIPanGestureRecognizer *)pan
{
    CGFloat center = [pan locationInView:self.renderTarget].y / self.renderTarget.frame.size.height;
    if (pan.state == UIGestureRecognizerStateBegan) {
        [[DHImageEditor sharedEditor] startLinearTiltShiftInputWithValue:center];
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        [[DHImageEditor sharedEditor] updateWithInput:center];
    } else {
        [[DHImageEditor sharedEditor] finishLinearTiltShiftInputWithValue:center];
    }
}

#pragma mark - DHSliderInputPanelDelegate
- (void) inputPanelDidCancel
{
    if (self.colorPicker) {
        [[DHImageEditor sharedEditor] restoreIntermediateState];
        [UIView animateWithDuration:0.2 animations:^{
            self.colorPicker.view.alpha = 1.f;
            self.editPanel.alpha = 0.01;
        }];
    } else {
        [[DHImageEditor sharedEditor] cancelProcessingCurrentComponent];
        [self hideValieInputPanel];
    }
}

- (void) inputPanelDidComplete
{
    if (self.colorPicker) {
        [[DHImageEditor sharedEditor] saveInterMediateState];
        [UIView animateWithDuration:0.2 animations:^{
            self.colorPicker.view.alpha = 1.f;
            self.editPanel.alpha = 0.01;
        }];
    }  else {
        [self hideValieInputPanel];
    }
}

- (void) inputPanel:(DHSliderInputPanel *)panel didChangeValue:(CGFloat)value
{
    NSLog(@"value = %g", value);
    [[DHImageEditor sharedEditor] updateWithInput:value];
}

- (void) tiltTypePickerDidPickRadial
{
    [[DHImageEditor sharedEditor] startProcessingComponent:DHImageEditComponentTiltShift subComponent:DHTiltShiftSubTypeRadial];
}

- (void) tiltTypePickerDidPickLinear
{
    [[DHImageEditor sharedEditor] startProcessingComponent:DHImageEditComponentTiltShift subComponent:DHTiltShiftSubTypeLinear];
}

#pragma mark - DHColorPickerCollectionViewController
- (void) colorPickerDidFinish
{
    [[DHImageEditor sharedEditor] finishProcessingCurrentComponent];
    [self hideColorPicker];
}

- (void) colorPickerDidCancel
{
    [[DHImageEditor sharedEditor] cancelProcessingCurrentComponent];
    [self hideColorPicker];
}

- (void) colorPickerDidPickColor:(UIColor *)color
{
    [[DHImageEditor sharedEditor] updateWithColor:color];
    DHImageEditorValues values = [DHImageHelper valuesforComponent:DHImageEditComponentColor];
    DHSliderInputPanel *inputPanel = [[DHSliderInputPanel alloc] initWithFrame:self.containerView.bounds];
    inputPanel.delegate = self;
    inputPanel.alpha = 0.01;
    [inputPanel setMinValue:values.minValue];
    [inputPanel setMaxValue:values.maxValue];
    NSDictionary *initialParameters = [[DHImageEditor sharedEditor] initialParameters];
    CGFloat inputValue = [[[initialParameters allValues] lastObject] doubleValue];
    [inputPanel setInitialValue:inputValue];
    NSLog(@"----------inputValue = %g", inputValue);
    self.editPanel = inputPanel;
    [self.containerView addSubview:inputPanel];
    [UIView animateWithDuration:0.2 animations:^{
        inputPanel.alpha = 1.f;
        self.colorPicker.view.alpha = 0.01;
    }];
}

- (IBAction)showFilters:(id)sender {
    if (sender == nil) {
        [self addChildViewController:self.filterPicker toParentViewController:self inContainerView:self.containerView];
    } else {
        self.filterPicker.view.alpha = 0.01;
        [self addChildViewController:self.filterPicker toParentViewController:self inContainerView:self.containerView];
        [UIView animateWithDuration:0.2 animations:^{
            self.filterPicker.view.alpha = 1.f;
            self.editorPicker.view.alpha = 0.01f;
        } completion:^(BOOL finished) {
            [self removeChildViewController:self.editorPicker fromParentViewController:self];
        }];
    }
}

- (IBAction)showEdit:(id)sender {
    self.editorPicker.view.alpha = 0.01;
    [self addChildViewController:self.editorPicker toParentViewController:self inContainerView:self.containerView];
    [UIView animateWithDuration:0.2 animations:^{
        self.editorPicker.view.alpha = 1.f;
        self.filterPicker.view.alpha = 0.01f;
    } completion:^(BOOL finished) {
        [self removeChildViewController:self.filterPicker fromParentViewController:self];
    }];
}

#pragma mark - DHIFFilterPickerCollectionViewControllerDelegate
- (void) filterPickerDidPickFilter:(IFImageFilter *)filter
{
    [[DHImageEditor sharedEditor] startProcessingWithFilter:filter];
}
#pragma mark - Helper
- (void) addChildViewController:(UIViewController *)viewController
         toParentViewController:(UIViewController *)parentViewController
                inContainerView:(UIView *)containerView
{
    [parentViewController addChildViewController:viewController];
    [containerView addSubview:viewController.view];
    [viewController didMoveToParentViewController:parentViewController];
}

- (void) removeChildViewController:(UIViewController *)viewController
          fromParentViewController:(UIViewController *)parentViewController
{
    [viewController willMoveToParentViewController:nil];
    [viewController.view removeFromSuperview];
    [viewController removeFromParentViewController];
}

- (void) hideColorPicker
{
    [UIView animateWithDuration:0.2 animations:^{
        self.colorPicker.view.alpha = 0.01;
        self.editorPicker.view.alpha = 1.f;
    } completion:^(BOOL finished) {
        [self removeChildViewController:self.colorPicker fromParentViewController:self];
        self.colorPicker = nil;
    }];
}

@end