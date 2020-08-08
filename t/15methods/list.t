use xcl::test;

let lst = (1, 2, 3);

is lst.pipe(x => { x + 1 }) (2, 3, 4) 'basic pipe';

is lst.pipe(x => { (x, x + 1) }) (1, 2, 2, 3, 3, 4) 'list pipe';

is lst.map(x => { x + 1 }) (2, 3, 4) 'basic map';

is lst.map(x => { (x, x + 1) }) ((1, 2), (2, 3), (3, 4)) 'list map';

let lst = (1, 0, 1, 0, 1);

is lst.where(x => { x }) (1, 1, 1) 'basic where';

var acc = ();

is lst.where(x => { acc = acc ++ (x); x }).map(x => { acc = acc ++ (x+1); x+1 })
  (2, 2, 2) 'chain where + map';

is acc (1, 2, 0, 1, 2, 0, 1, 2) 'streaming chain';

let lst = mut (1, 2, 3);

lst(0) = 4;

is lst (4, 2, 3) 'mutated list';
