//
//  BPFormViewController.m
//
//  Copyright (c) 2014 Bogdan Poplauschi
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.


#import "BPFormViewController.h"
#import "BPAppearance.h"
#import "BPFormCell.h"
#import "BPFormInputCell.h"
#import "BPFormTextField.h"
#import "BPFormInfoCell.h"
#import <Masonry.h>


@interface BPFormViewController ()

@property (nonatomic, strong) NSMutableDictionary *sectionHeaderTitles; // dictionary holding (section, title) pairs
@property (nonatomic, strong) NSMutableDictionary *sectionFooterTitles; // dictionary holding (section, title) pairs

@end


@implementation BPFormViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.sectionHeaderTitles = [NSMutableDictionary dictionary];
        self.sectionFooterTitles = [NSMutableDictionary dictionary];
        
        self.customSectionHeaderHeight = 0.0;
        self.customSectionFooterHeight = 0.0;
        
        [self setupTableView];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // need to react to keyboard, in detail make the table view visible at all time, so scrolling is available when the keyboard is on
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)keyboardDidShow:(NSNotification *)inNotification {
    // make the tableview fit the visible area of the screen, so it's scrollable to all the cells
    // note: for landscape, the sizes are switched, so we need to use width as height
    
    CGSize keyboardSize = [[[inNotification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    CGFloat keyboardHeight = (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])) ? keyboardSize.width : keyboardSize.height;
    
    [self.tableView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(self.view.mas_height).with.offset(-keyboardHeight);
    }];
}

- (void)keyboardDidHide:(NSNotification *)inNotification {
    [self.tableView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(self.view.mas_height);
    }];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
    self.tableView.backgroundView = nil;
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view.mas_width);
        make.height.equalTo(self.view.mas_height);
        make.top.equalTo(self.view.mas_top);
        make.left.equalTo(self.view.mas_left);
    }];
    
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [BPAppearance sharedInstance].tableViewBackGroundColor;
}

- (void)setHeaderTitle:(NSString *)inHeaderTitle forSection:(int)inSection {
    if ([inHeaderTitle length] && inSection >= 0) {
        self.sectionHeaderTitles[@(inSection)] = inHeaderTitle;
    }
}

- (void)setFooterTitle:(NSString *)inFooterTitle forSection:(int)inSection {
    if ([inFooterTitle length] && inSection >= 0) {
        self.sectionFooterTitles[@(inSection)] = inFooterTitle;
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.formCells) {
        return self.formCells.count;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.formCells && (section < self.formCells.count) ) {
        return [self.formCells[section] count];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.formCells && (indexPath.section < self.formCells.count) ) {
        NSArray *sectionCells = self.formCells[indexPath.section];
        BPFormCell *cell = nil;
        if (indexPath.row < sectionCells.count) {
            cell = self.formCells[indexPath.section][indexPath.row];
            [cell refreshMandatoryState];
        }
        return cell;
    }
    return nil;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.formCells && (indexPath.section < self.formCells.count) ) {
        NSArray *sectionCells = self.formCells[indexPath.section];
        if (indexPath.row < sectionCells.count) {
            BPFormCell *cell = self.formCells[indexPath.section][indexPath.row];
            return [cell cellHeight];
        }
    }
    return 0.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *headerTitle = self.sectionHeaderTitles[@(section)];
    if (headerTitle) {
        CGFloat headerHeight = self.customSectionHeaderHeight ?: [self.tableView sectionHeaderHeight];
        UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tableView.frame.size.width, headerHeight)];
        infoLabel.text = headerTitle;
        infoLabel.textColor = [BPAppearance sharedInstance].headerFooterLabelTextColor;
        infoLabel.font = [BPAppearance sharedInstance].headerFooterLabelFont;
        infoLabel.textAlignment = NSTextAlignmentCenter;
        return infoLabel;
    }
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.customSectionHeaderHeight) {
        return self.customSectionHeaderHeight;
    }
    return [self.tableView sectionHeaderHeight];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    NSString *footerTitle = self.sectionFooterTitles[@(section)];
    if (footerTitle) {
        CGFloat footerHeight = self.customSectionFooterHeight ?: [self.tableView sectionFooterHeight];
        UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tableView.frame.size.width, footerHeight)];
        infoLabel.text = footerTitle;
        infoLabel.textColor = [BPAppearance sharedInstance].headerFooterLabelTextColor;
        infoLabel.font = [BPAppearance sharedInstance].headerFooterLabelFont;
        infoLabel.textAlignment = NSTextAlignmentCenter;
        return infoLabel;
    }
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (self.customSectionFooterHeight) {
        return self.customSectionFooterHeight;
    }
    return [self.tableView sectionFooterHeight];
}

#pragma mark - UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    BPFormInputCell *cell = nil;
    if ([textField isKindOfClass:[BPFormTextField class]]) {
        cell = [((BPFormTextField *)textField) containerTableViewCell];
    }
    if (!cell) {
        return;
    }
    if (cell.didBeginEditingBlock) {
        cell.didBeginEditingBlock(cell, textField.text);
    }
    [self updateInfoCellBelowInputCell:cell];
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    BOOL shouldChange = YES;
    BPFormInputCell *cell = nil;
    if ([textField isKindOfClass:[BPFormTextField class]]) {
        cell = [((BPFormTextField *)textField) containerTableViewCell];
    }
    if (!cell) {
        return YES;
    }

    NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (cell.shouldChangeTextBlock) {
        shouldChange = cell.shouldChangeTextBlock(cell, newText);
    }
    [self updateInfoCellBelowInputCell:cell];
    [cell updateAccordingToValidationState];
    
    return shouldChange;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    BPFormInputCell *cell = nil;
    if ([textField isKindOfClass:[BPFormTextField class]]) {
        cell = [((BPFormTextField *)textField) containerTableViewCell];
    }
    if (!cell) {
        return;
    }
    
    // executing the shouldChangeTextBlock to validate the text
    if (cell.shouldChangeTextBlock) {
        cell.shouldChangeTextBlock(cell, textField.text);
    }
    
    if (cell.didEndEditingBlock) {
        cell.didEndEditingBlock(cell, textField.text);
    }
    
    [self updateInfoCellBelowInputCell:cell];
    [cell updateAccordingToValidationState];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    BOOL shouldReturn = YES;
    BPFormInputCell *cell = nil;
    if ([textField isKindOfClass:[BPFormTextField class]]) {
        cell = [((BPFormTextField *)textField) containerTableViewCell];
    }
    if (!cell) {
        return YES;
    }
    
    if (cell.shouldReturnBlock) {
        shouldReturn = cell.shouldReturnBlock(cell, textField.text);
    }
    
    BPFormInputCell *nextCell = [self nextInputCell:cell];
    if (!nextCell) {
        [cell.textField resignFirstResponder];
    } else {
        [nextCell.textField becomeFirstResponder];
    }
    
    [self updateInfoCellBelowInputCell:cell];
    return shouldReturn;
}

- (BPFormInputCell *)nextInputCell:(BPFormInputCell *)currentCell {
    BOOL foundCurrentCell = NO;
    
    for (NSArray *section in self.formCells) {
        for (BPFormCell *cell in section) {
            if (!foundCurrentCell) {
                if (cell == currentCell) {
                    foundCurrentCell = YES;
                }
            } else {
                if ([cell isKindOfClass:[BPFormInputCell class]]) {
                    return (BPFormInputCell *)cell;
                }
            }
        }
    }
    return nil;
}

#pragma mark - Show / hide info cells
- (BPFormInfoCell *)infoCellBelowInputCell:(BPFormInputCell *)inInputCell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:inInputCell];
    NSIndexPath *nextPath = [NSIndexPath indexPathForRow:(indexPath.row + 1) inSection:indexPath.section];
    UITableViewCell *cellBelow = [self.tableView cellForRowAtIndexPath:nextPath];
    if (cellBelow && [cellBelow isKindOfClass:[BPFormInfoCell class]]) {
        return (BPFormInfoCell *)cellBelow;
    }
    return nil;
}

- (void)showInfoCellBelowInputCell:(BPFormInputCell *)inInputCell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:inInputCell];
    
    BPFormInfoCell *infoCell = [self infoCellBelowInputCell:inInputCell];
    if (infoCell)
        return;
    
    NSMutableArray *newFormCells = [NSMutableArray array];
    for (int sectionIndex=0; sectionIndex<self.formCells.count; sectionIndex++) {
        NSArray *section = self.formCells[sectionIndex];
        if (sectionIndex == indexPath.section) {
            NSMutableArray *newSection = [NSMutableArray arrayWithArray:section];
            [newSection insertObject:inInputCell.infoCell atIndex:indexPath.row + 1];
            [newFormCells addObject:newSection];
        } else {
            [newFormCells addObject:section];
        }
    }
    self.formCells = [newFormCells copy];
    
    NSIndexPath *nextPath = [NSIndexPath indexPathForRow:(indexPath.row + 1) inSection:indexPath.section];
    
    [self.tableView insertRowsAtIndexPaths:@[nextPath]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)removeInfoCellBelowInputCell:(BPFormInputCell *)inInputCell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:inInputCell];
    
    BPFormInfoCell *infoCell = [self infoCellBelowInputCell:inInputCell];
    if (!infoCell)
        return;
    
    NSMutableArray *newFormCells = [NSMutableArray array];
    for (int sectionIndex=0; sectionIndex<self.formCells.count; sectionIndex++) {
        NSArray *section = self.formCells[sectionIndex];
        if (sectionIndex == indexPath.section) {
            NSMutableArray *newSection = [NSMutableArray arrayWithArray:section];
            [newSection removeObjectAtIndex:indexPath.row + 1];
            [newFormCells addObject:newSection];
        } else {
            [newFormCells addObject:section];
        }
    }
    self.formCells = [newFormCells copy];
    
    NSIndexPath *nextPath = [NSIndexPath indexPathForRow:(indexPath.row + 1) inSection:indexPath.section];
    [self.tableView deleteRowsAtIndexPaths:@[nextPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)updateInfoCellBelowInputCell:(BPFormInputCell *)inInputCell {
    if (inInputCell.shouldShowInfoCell && !inInputCell.textField.editing) {
        [self showInfoCellBelowInputCell:inInputCell];
    } else {
        [self removeInfoCellBelowInputCell:inInputCell];
    }
}


@end
