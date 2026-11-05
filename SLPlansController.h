#import <UIKit/UIKit.h>
#import "SLPickerController.h"

/* Zakładka "Plany": własne plany treningowe i gotowe programy. */
@interface SLPlansController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>
@end

/* Ćwiczenia jednego planu (własnego albo z gotowego programu). */
@interface SLPlanDetailController : UIViewController <UITableViewDataSource, UITableViewDelegate, SLPickerDelegate, UIAlertViewDelegate>
- (id)initWithPlanId:(NSString *)planId;                               /* własny plan: edytowalny */
- (id)initWithTemplateName:(NSString *)name exercises:(NSArray *)ids;   /* z gotowego programu: tylko podgląd */
@end

/* Dni gotowego programu. */
@interface SLProgramController : UIViewController <UITableViewDataSource, UITableViewDelegate>
- (id)initWithProgramIndex:(NSInteger)index;
@end

/* Pomocnik: nowy plan z listy ćwiczeń (np. z historii). Pyta o nazwę. */
void SLPromptSavePlan(NSString *suggestedName, NSArray *exerciseIds, id owner);
