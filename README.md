#KKGridView

High-performance iOS grid view (MIT license). **Requirements**: you need
to build `KKGridView` with a compiler that supports *Automatic Reference
Counting*. We know this stings at first, but we strongly believe that
the future is better served by requiring this now. Moreover, the move to
ARC improved `KKGridView`'s performance greatly. Remember that your
project need not use ARC to include `KKGridView`.

### Contributing
If you see something you don't like, you are always welcome to submit it
as an issue. But if you can find it in your heart, we'd be so grateful
if you would fix it yourself and send us a pull request. We promise not
to bite!


##Current Issues

Most features, bugs, and missing items for the project are in the Issues section.  Currently, there are placement issues after inserting.  We were initially going to fix these before public release, but instead decided to release now and allow outside contribution.
Other than that, editing and selection are the only things that need work.

##Motivations

`KKGridView` was created in July 2011 for usage in [StratusApp](http://getstratusapp.com/).  When I discovered that this would be both very difficult and time consuming, I sought out the help of [Giulio Petek](http://twitter.com/GiloTM) and [Jonathan Sterling](http://twitter.com/jonsterling).  Additionally, we brought on [Kyle Hickinson](http://twiter.com/kylehickinson), [Matthias Tretter](http://twitter.com/myell0w), and most recently, [Peter Steinberger](http://twitter.com/steipete).  Luckily, all of my fellow collaborators shared the common opinion that all of the grid views available now are slow, feature-incomplete, and coded in an inextensible fashion.  With this in mind, we set out to create the best grid view component available for iOS to-date.

##Goals

When we set out building this, we all had a few common things we knew we needed to focus on.

* Performance — 55+ FPS in the worst case.
* `UITableView` similarities — Strive to be as close to drop-in as possible.
* Feature completeness — As above, match the latest UITableView implementation in features; add anything else worthwhile.
* Solid codebase — We didn't want something that was inextensible and 
full of messy code.


##Usage
**This is liable to change as a `KKGridViewController` is added as a correspondence to `UITableViewController`.**

First, instantiate a grid view instance.  *Using the designated initializer and a `_gridView` ivar:*

~~~~objc
_gridView = [[KKGridView alloc] initWithFrame:self.view.bounds dataSource:self delegate:self];
~~~~

Now, you can setup your default `UIScrollView` and `UIView` properties, since `KKGridView` inherits from said class.

~~~~objc
_gridView.scrollsToTop = YES;
_gridView.backgroundColor = [UIColor darkGrayColor];
_gridView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
~~~~

Metrics must also be set (automatic sizing *may* come in the future).

~~~~objc
_gridView.cellSize = CGSizeMake(75.f, 75.f);
_gridView.cellPadding = CGSizeMake(4.f, 4.f);
~~~~

Now, other properties available in the header file can be set.

~~~~objc
_gridView.allowsMultipleSelection = NO;

UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 50.f)];
headerView.backgroundColor = [UIColor redColor];
_gridView.gridHeaderView = headerView;
[headerView release] /* For the non-ARC users amongst us */
~~~~

Finally, you can set the grid as your view.

~~~~objc
self.view = _gridView;
~~~~

Alternatively, you can add the grid to your view-hierarchy.

~~~~objc
[self.view addSubview:_gridView];
~~~~

###Data source methods:

~~~~objc
- (NSUInteger)gridView:(KKGridView *)gridView numberOfItemsInSection:(NSUInteger)section
{
		switch (section) {
				case 0:
						return kFirstSectionCount;
						break;
				case 1:
						return 15;
						break;
				case 2:
						return 10;
						break;
				case 3:
						return 5;
						break;
				default:
						return 0;
						break;
		}
}
~~~~

Optionally, you can specify how many section you would like in the grid. *(Default is 1)*

~~~~objc
- (NSUInteger)numberOfSectionsInGridView:(KKGridView *)gridView
{
		return kNumSection;
}
~~~~

The last required method is to return a cell, just like UITableView.  We've made it easier on you, though.

*`KKIndexPath` works in just the same way as `NSIndexPath`, only `-row` is replaced with `-index`.*

*`KKGridViewCell`, like `UITableViewCell`, is designed to be subclassed.*

~~~~objc
- (KKGridViewCell *)gridView:(KKGridView *)gridView cellForRowAtIndexPath:(KKIndexPath *)indexPath
{
		KKGridViewCell *cell = [KKGridViewCell cellForGridView:gridView];
		
		cell.backgroundColor = [UIColor lightGrayColor];
		
		return cell;
}
~~~~objc


There are no required delegate methods, though all that are implemented in `UITableView` will soon be available in `KKGridView`.
