#import "SLPickerController.h"

/* Zakładka "Ćwiczenia": ta sama lista co przy dodawaniu, ale dotknięcie otwiera statystyki. */
@interface SLExercisesController : SLPickerController
@end

@interface SLExerciseDetailController : UIViewController <UITableViewDataSource, UITableViewDelegate>
- (id)initWithExercise:(NSDictionary *)exercise;
@end
