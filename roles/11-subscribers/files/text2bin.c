# include <stdio.h>
# include <string.h>

int main(int argc, char **argv){
   int i, c, d;
   char *f = argv[1];
      
   for(i = 0; i < strlen(f); i++){
      if(f[i] >= 'a' && f[i] <= 'f'){
         c = f[i] - 'a' + 10;
      }
      
      else if(f[i] >= 'A' && f[i] <= 'F'){
         c = f[i] - 'a' + 10;
      }      
      
      else if(f[i] >= '0' && f[i] <= '9'){
         c = f[i] - '0';         
      }
      
      if(i % 2 == 0){
         d = c;
      }
      else{
         d = d*0x10 + c;
         printf("%c", d);
      }
      
   }
}
