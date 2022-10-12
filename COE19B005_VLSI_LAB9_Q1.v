//Lift Simulation
`timescale 1ns/1ps

module LFT(Inp);
    input[11:0] Inp;
    reg[3:0][9:0] L;//Holds Lift Requests For all 4 Lifts (0: Not-Requested 1: Requested)
    reg[3:0][1:0] D;//Holds the Current Direction of Lifts(0: At-Rest 1: Going-Up 2: Going-Down)
    reg[3:0][3:0] S;//Holds the Current States of all 4 lifts(0 to 9 to denote 10 floors)
    reg[3:0][3:0] R;//Holds the State towads which the Lift is Going(0 to 9 to denote 10 floors)
    
    //Following variables used for calculation purposes as we need to minimize average waiting time
    reg[3:0][3:0] H;//Holds Hop Count of Lifts
    reg[3:0][9:0] KL;//Temporary registers to store Lift requests of a particular Lift
    reg[9:0] TL;//Temporary registers to store Lift requests of a particular Lift
    reg[3:0] Oflag;//Flag Holds if the Lift is Open or Not
    reg[3:0] DFlag;//Flag to indicate change the direction so wait time reduced
    integer i,j,r;//Iterators
    reg[3:0] Flag;//Intially when at rest, used to decide in which direction the request is near.(0-Bottom 1-Top)

    initial
    begin
        L=0;D=0;S=0;R=0;H=0;    
    end

//Initializing Requests
    always@(Inp)
    begin
        L[Inp[11:10]]=L[Inp[11:10]] | Inp[9:0];//ORed because when already request is ON, till its request completed it won't turn it off.
    end

//Displays Changes In Lift States
    always@(L,S,D,Oflag)
    begin
        $display("--------------------LIFTS----------------------");
        for(integer n=9;n!=-1;--n)
        begin
            for(integer m=0;m<4;++m)
            begin
                TL=L[m];
                if(n==S[m])
                    if(Oflag[m])
                        $write("[]");  
                    else if(D[m]==1)
                        $write("^ ");  
                    else if(D[m]==2)
                        $write("v ");
                    else
                        $write("I ");
                else if(TL[n]==1)
                    $write("+ ");
                else
                    $write("- ");
            end
            $write("\n");
        end
        $display("--------------------LIFTS----------------------");
    end

//Lift 0
    always@(L[0])
    begin
        R[0]=S[0];//initially made same to make it decide the direction.
        D[0]=0;//As initially Lift is at rest

        //Finding Which Direction is Near
        for(i=S[0]+1;i<10 && L[0][i]==0;++i);
        for(j=S[0]-1;i!=-1 && L[0][j]==0;--j);
        if(i==10)
            Flag[0]=0;
        else if(j==-1)
            Flag[0]=1;
        else if(i-S[0]<=S[0]-j)
            Flag[0]=1;
        else
            Flag[0]=0;

        //Till all requests are satisfied keep running
        while(L[0]!=0)
        begin
            if(L[0][S[0]]==1)//Services The Floor
            begin
                #1 Oflag[0]=1;
                #1 Oflag[0]=0;
                L[0][S[0]]=0;
            end
            
            if(S[0]==R[0])//at reached state or floor
            begin
                if(D[0]==1 || Flag[0]==1)//if going up currently
                begin
                    //Finding if any requests are there above, if any the nearest is obtained in 'i'
                    i=S[0]+1;
                    while(i<10 && L[0][i]==0)
                    begin
                        i=i+1;
                    end

                    if(i<10)//Yes at top floor someone requested
                    begin
                            for(integer k=0;k<4;++k)//See if Other Lifts are near them by calculating hop count
                            begin
                                KL[0]=L[k];
                                if(KL[0][i]==1)
                                    begin
                                    if(D[k]==1 || D[k]==0)//If other one moves in same direction or is at rest
                                    begin
                                        if(i>=S[k])//Going towards it so calculate hop count
                                        begin
                                            H[k]=i-S[k];
                                        end
                                        else//already crossed the floor set to high
                                        begin
                                            H[k]=10;
                                        end
                                    end
                                    else if(D[k]==2)//If other one moves in opposite direction or is at rest
                                    begin
                                        if(i>S[k])//already crossed the floor set to high
                                        begin
                                            H[k]=10;
                                        end
                                        else//Going towards it so calculate hop count
                                        begin
                                            H[k]=S[k]-i;
                                            for(integer p=S[k]+1;p<10;++p)//If there are other requests to this lift at top of other states then set high hop count
                                            begin
                                                if(L[0][p]==1)
                                                    H[k]=10;
                                            end
                                        end
                                    end
                                end
                                else
                                    H[k]=10;
                            end

                            DFlag[0]=0;
                            for(integer k=0;k<4;++k)//Change Direction if other lifts can service the top floors earlier than this.
                            begin
                                if(H[k]<H[0])
                                    DFlag[0]=1;
                            end
                            if(DFlag[0]==1)//Changes
                                D[0]=2;
                            else//Remains Same
                                D[0]=1;
                    end
                    else//If no request at top exists
                    begin
                        if(L[0]==0)//If no requests at bottom also
                            D[0]=0;
                        else
                            D[0]=2;
                    end

                    //Get what state to go next
                    if(D[0]==1)
                        R[0]=i;
                    else if(D[0]==2)
                    begin
                        for(r=S[0]-1;r!=-1 && L[0][r]==0;--r);//Finds Nearest Bottom Request
                        R[0]=r;
                        if(R[0]==15)//Boundary Condition When lift is at the least floor
                        begin
                            D[0]=1;
                            R[0]=i;
                        end
                    end
                end
                else if(D[0]==2 || Flag[0]==0)//if going down currently
                begin

                    //Finding if any requests are there below, if any the nearest is obtained in 'i'
                    i=S[0]-1;
                    while(i!=-1 && L[0][i]==0)//See if bottom floors requested
                    begin
                        i=i-1;
                    end

                    if(i!=-1)//Yes at bottom floor someone requested
                    begin   
                            for(integer k=0;k<4;++k)//See if Other Lifts are near them by calculating hop count
                            begin
                                KL[0]=L[k];
                                if(KL[0][i]==1)
                                    begin
                                    if(D[k]==2 || D[k]==0)//If other one moves in same direction or is at rest
                                    begin
                                        if(i<=S[k])//Going towards it so calculate hop count
                                        begin
                                            H[k]=S[k]-i;
                                        end
                                        else//already crossed the floor set to high
                                        begin
                                            H[k]=10;
                                        end
                                    end
                                    else if(D[k]==1)//If other one moves in opposite direction or is at rest
                                    begin
                                        if(i<S[k])//already crossed the floor set to high
                                        begin
                                            H[k]=10;
                                        end
                                        else//Going towards it so calculate hop count
                                        begin
                                            H[k]=i-S[k];
                                            for(integer p=S[k]-1;p>0;--p)//If there are other requests to this lift at bottom of other states then set high hop count
                                            begin
                                                if(L[0][p]==1)
                                                    H[k]=10;
                                            end
                                        end
                                    end
                                    end
                                else
                                    H[k]=10;
                            end

                            DFlag[0]=0;
                            for(integer k=0;k<4;++k)//Change Direction if other lifts can service the bottom floors earlier than this.
                            begin
                                if(H[k]<H[0])
                                    DFlag[0]=1;
                            end
                            if(DFlag[0]==1)//Changes
                                D[0]=1;
                            else//Remains Same
                                D[0]=2;
                    end
                    else//If no request at bottom exists
                    begin
                        if(L[0]==0)//If no requests at top also
                            D[0]=0;
                        else
                            D[0]=1;
                    end

                    //Get what state to go next    
                    if(D[0]==2)
                        R[0]=i;
                    else if(D[0]==1)
                    begin
                        for(r=S[0]+1;r<10 && L[0][r]==0;++r);//Finds Nearest Top Request
                        R[0]=r;
                        if(R[0]==10)//Boundary Condition When lift is at the Top most floor
                        begin
                            D[0]=2;
                            R[0]=i;
                        end
                    end
                end
            end

            //Direction Decided
            if(D[0]==1)//Go up
            begin
                S[0]=S[0]+1;
                #1;
            end
            else if(D[0]==2)//Go Down
            begin
                S[0]=S[0]-1;
                #1;
            end
            else//Stop
            begin
                #1;
            end
        end
    end

//Lift 1
    always@(L[1])
    begin
        R[1]=S[1];//initially made same to make it decide the direction.
        D[1]=0;//As initially Lift is at rest

        //Finding Which Direction is Near
        for(i=S[1]+1;i<10 && L[1][i]==0;++i);
        for(j=S[1]-1;i!=-1 && L[1][j]==0;--j);
        if(i==10)
            Flag[1]=0;
        else if(j==-1)
            Flag[1]=1;
        else if(i-S[1]<=S[1]-j)
            Flag[1]=1;
        else
            Flag[1]=0;

        //Till all requests are satisfied keep running
        while(L[1]!=0)
        begin
            if(L[1][S[1]]==1)//Services The Floor
            begin
                #1 Oflag[1]=1;
                #1 Oflag[1]=0;
                L[1][S[1]]=0;
            end

            if(S[1]==R[1])//at reached state or floor
            begin
                if(D[1]==1 || Flag[1]==1)//if going up currently
                begin

                    //Finding if any requests are there above, if any the nearest is obtained in 'i'
                    i=S[1]+1;
                    while(i<10 && L[1][i]==0)
                    begin
                        i=i+1;
                    end

                    if(i<10)//Yes at top floor someone requested
                    begin
                            for(integer k=0;k<4;++k)//See if Other Lifts are near them by calculating hop count
                            begin
                                KL[1]=L[k];
                                if(KL[1][i]==1)
                                begin
                                    if(D[k]==1 || D[k]==0)//If other one moves in same direction or is at rest
                                    begin
                                        if(i>=S[k])//Going towards it so calculate hop count
                                        begin
                                            H[k]=i-S[k];
                                        end
                                        else//already crossed the floor set to high
                                        begin
                                            H[k]=10;
                                        end
                                    end
                                    else if(D[k]==2)//If other one moves in opposite direction or is at rest
                                    begin
                                        if(i>S[k])//already crossed the floor set to high
                                        begin
                                            H[k]=10;
                                        end
                                        else//Going towards it so calculate hop count
                                        begin
                                            H[k]=S[k]-i;
                                            for(integer p=S[k]+1;p<10;++p)//If there are other requests to this lift at top of other states then set high hop count
                                            begin
                                                if(L[1][p]==1)
                                                    H[k]=10;
                                            end
                                        end
                                    end
                                end
                                else
                                    H[k]=10;
                            end
                            DFlag[1]=0;
                            for(integer k=0;k<4;++k)//Change Direction if other lifts can service the top floors earlier than this.
                            begin
                                if(H[k]<H[1])
                                    DFlag[1]=1;
                            end
                            if(DFlag[1]==1)//Changes
                                D[1]=2;
                            else//Remains Same
                                D[1]=1;
                    end
                    else//If no request at top exists
                    begin
                        if(L[1]==0)//If no requests at bottom also
                            D[1]=0;
                        else
                            D[1]=2;
                    end

                    //Get what state to go next
                    if(D[1]==1)
                        R[1]=i;
                    else if(D[1]==2)
                    begin
                        for(r=S[1]-1;r!=-1 && L[1][r]==0;--r);//Finds Nearest Bottom Request
                        R[1]=r;
                        if(R[1]==15)//Boundary Condition When lift is at the least floor
                        begin
                            D[1]=1;
                            R[1]=i;
                        end
                    end
                end
                else if(D[1]==2 || Flag[1]==0)//if going down currently
                begin

                    //Finding if any requests are there below, if any the nearest is obtained in 'i'
                    i=S[1]-1;
                    while(i!=-1 && L[1][i]==0)//See if bottom floors requested
                    begin
                        i=i-1;
                    end
                    
                    if(i!=-1)//Yes at bottom floor someone requested
                    begin   
                            for(integer k=0;k<4;++k)//See if Other Lifts are near them by calculating hop count
                            begin
                                KL[1]=L[k];
                                if(KL[1][i]==1)
                                    begin
                                    if(D[k]==2 || D[k]==0)//If other one moves in same direction or is at rest
                                    begin
                                        if(i<=S[k])//Going towards it so calculate hop count
                                        begin
                                            H[k]=S[k]-i;
                                        end
                                        else//already crossed the floor set to high
                                        begin
                                            H[k]=10;
                                        end
                                    end
                                    else if(D[k]==1)//If other one moves in opposite direction or is at rest
                                    begin
                                        if(i<S[k])//already crossed the floor set to high
                                        begin
                                            H[k]=10;
                                        end
                                        else//Going towards it so calculate hop count
                                        begin
                                            H[k]=i-S[k];
                                            for(integer p=S[k]-1;p>0;--p)//If there are other requests to this lift at bottom of other states then set high hop count
                                            begin
                                                if(L[1][p]==1)
                                                    H[k]=10;
                                            end
                                        end
                                    end
                                    end
                                else
                                    H[k]=10;
                            end

                            DFlag[1]=0;
                            for(integer k=0;k<4;++k)//Change Direction if other lifts can service the bottom floors earlier than this.
                            begin
                                if(H[k]<H[1])
                                    DFlag[1]=1;
                            end
                            if(DFlag[1]==1)//Changes
                                D[1]=1;
                            else//Remains Same
                                D[1]=2;
                    end
                    else//If no request at bottom exists
                    begin
                        if(L[1]==0)//If no requests at top also
                            D[1]=0;
                        else
                            D[1]=1;
                    end

                    //Get what state to go next
                    if(D[1]==2)
                        R[1]=i;
                    else if(D[1]==1)
                    begin
                        for(r=S[1]+1;r<10 && L[1][r]==0;++r);//Finds Nearest Top Request
                        R[1]=r;
                        if(R[1]==10)//Boundary Condition When lift is at the Top most floor
                        begin
                            D[1]=2;
                            R[1]=i;
                        end
                    end
                end
            end

            //Direction Decided
            if(D[1]==1)//Go up
            begin
                S[1]=S[1]+1;
                #1;
            end
            else if(D[1]==2)//Go Down
            begin
                S[1]=S[1]-1;
                #1;
            end
            else//Stop
            begin
                #1;
            end
        end
    end

//Lift 2
    always@(L[2])
    begin
        R[2]=S[2];//initially made same to make it decide the direction.
        D[2]=0;//As initially Lift is at rest

        //Finding Which Direction is Near
        for(i=S[2]+1;i<10 && L[2][i]==0;++i);
        for(j=S[2]-1;i!=-1 && L[2][j]==0;--j);
        if(i==10)
            Flag[2]=0;
        else if(j==-1)
            Flag[2]=1;
        else if(i-S[2]<=S[2]-j)
            Flag[2]=1;
        else
            Flag[2]=0;

        //Till all requests are satisfied keep running
        while(L[2]!=0)
        begin
            if(L[2][S[2]]==1)//Services the Floor
            begin
                #1 Oflag[2]=1;
                #1 Oflag[2]=0;
                L[2][S[2]]=0;
            end
            if(S[2]==R[2])//at reached state or floor
            begin
                if(D[2]==1 || Flag[2]==1)//if going up currently
                begin

                    //Finding if any requests are there above, if any the nearest is obtained in 'i'
                    i=S[2]+1;
                    while(i<10 && L[2][i]==0)
                    begin
                        i=i+1;
                    end

                    if(i<10)//Yes at top floor someone requested
                    begin
                            for(integer k=0;k<4;++k)//See if Other Lifts are near them by calculating hop count
                            begin
                                KL[2]=L[k];
                                if(KL[2][i]==1)
                                begin
                                    if(D[k]==1 || D[k]==0)//If other one moves in same direction or is at rest
                                    begin
                                        if(i>=S[k])//Going towards it so calculate hop count
                                        begin
                                            H[k]=i-S[k];
                                        end
                                        else//already crossed the floor set to high
                                        begin
                                            H[k]=10;
                                        end
                                    end
                                    else if(D[k]==2)//If other one moves in opposite direction or is at rest
                                    begin
                                        if(i>S[k])//already crossed the floor set to high
                                        begin
                                            H[k]=10;
                                        end
                                        else//Going towards it so calculate hop count
                                        begin
                                            H[k]=S[k]-i;
                                            for(integer p=S[k]+1;p<10;++p)//If there are other requests to this lift at top of other states then set high hop count
                                            begin
                                                if(L[2][p]==1)
                                                    H[k]=10;
                                            end
                                        end
                                    end
                                end
                                else
                                    H[k]=10;
                            end
                            DFlag[2]=0;
                            for(integer k=0;k<4;++k)//Change Direction if other lifts can service the top floors earlier than this.
                            begin
                                if(H[k]<H[2])
                                    DFlag[2]=1;
                            end
                            if(DFlag[2]==1)//Changes
                                D[2]=2;
                            else//Remains Same
                                D[2]=1;
                    end
                    else//If no request at top exists
                    begin
                        if(L[2]==0)//If no requests at bottom also
                            D[2]=0;
                        else
                            D[2]=2;
                    end

                    //Get what state to go next
                    if(D[2]==1)
                        R[2]=i;
                    else if(D[2]==2)
                    begin
                        for(r=S[2]-1;r!=-1 && L[2][r]==0;--r);//Finds Nearest Bottom Request
                        R[2]=r;
                        if(R[2]==15)//Boundary Condition When lift is at the least floor
                        begin
                            D[2]=1;
                            R[2]=i;
                        end
                    end
                end
                else if(D[2]==2 || Flag[2]==0)//if going down currently
                begin

                    //Finding if any requests are there below, if any the nearest is obtained in 'i'
                    i=S[2]-1;
                    while(i!=-1 && L[2][i]==0)//See if bottom floors requested
                    begin
                        i=i-1;
                    end

                    if(i!=-1)//Yes at bottom floor someone requested
                    begin   
                            for(integer k=0;k<4;++k)//See if Other Lifts are near them by calculating hop count
                            begin
                                KL[2]=L[k];
                                if(KL[2][i]==1)
                                    begin
                                    if(D[k]==2 || D[k]==0)//If other one moves in same direction or is at rest
                                    begin
                                        if(i<=S[k])//Going towards it so calculate hop count
                                        begin
                                            H[k]=S[k]-i;
                                        end
                                        else//already crossed the floor set to high
                                        begin
                                            H[k]=10;
                                        end
                                    end
                                    else if(D[k]==1)//If other one moves in opposite direction or is at rest
                                    begin
                                        if(i<S[k])//already crossed the floor set to high
                                        begin
                                            H[k]=10;
                                        end
                                        else//Going towards it so calculate hop count
                                        begin
                                            H[k]=i-S[k];
                                            for(integer p=S[k]-1;p>0;--p)//If there are other requests to this lift at bottom of other states then set high hop count
                                            begin
                                                if(L[2][p]==1)
                                                    H[k]=10;
                                            end
                                        end
                                    end
                                    end
                                else
                                    H[k]=10;
                            end

                            DFlag[2]=0;
                            for(integer k=0;k<4;++k)//Change Direction if other lifts can service the bottom floors earlier than this.
                            begin
                                if(H[k]<H[2])
                                    DFlag[2]=1;
                            end
                            if(DFlag[2]==1)//Changes
                                D[2]=1;
                            else//Remains Same
                                D[2]=2;
                    end
                    else//If no request at bottom exists
                    begin
                        if(L[2]==0)//If no requests at top also
                            D[2]=0;
                        else
                            D[2]=1;
                    end

                    //Get what state to go next
                    if(D[2]==2)
                        R[2]=i;
                    else if(D[2]==1)
                    begin
                        for(r=S[2]+1;r<10 && L[2][r]==0;++r);//Finds Nearest Top Request
                        R[2]=r;
                        if(R[2]==10)//Boundary Condition When lift is at the Top most floor
                        begin
                            D[2]=2;
                            R[2]=i;
                        end
                    end
                end
            end

            //Direction Decided
            if(D[2]==1)//Go Up
            begin
                S[2]=S[2]+1;
                #1;
            end
            else if(D[2]==2)//Go Down
            begin
                S[2]=S[2]-1;
                #1;
            end
            else//Stop
            begin
                #1;
            end
        end
    end

//Lift 3
    always@(L[3])
    begin
        R[3]=S[3];//initially made same to make it decide the direction.
        D[3]=0;//As initially Lift is at rest

        //Finding Which Direction is Near
        for(i=S[3]+1;i<10 && L[3][i]==0;++i);
        for(j=S[3]-1;i!=-1 && L[3][j]==0;--j);
        if(i==10)
            Flag[3]=0;
        else if(j==-1)
            Flag[3]=1;
        else if(i-S[3]<=S[3]-j)
            Flag[3]=1;
        else
            Flag[3]=0;

        //Till all requests are satisfied keep running
        while(L[3]!=0)
        begin
            if(L[3][S[3]]==1)//Services The Floor
            begin
                #1 Oflag[3]=1;
                #1 Oflag[3]=0;
                L[3][S[3]]=0;
            end
            if(S[3]==R[3])//at reached state or floor
            begin
                if(D[3]==1 || Flag[3]==1)//if going up currently
                begin

                    //Finding if any requests are there above, if any the nearest is obtained in 'i'
                    i=S[3]+1;
                    while(i<10 && L[3][i]==0)
                    begin
                        i=i+1;
                    end

                    if(i<10)//Yes at top floor someone requested
                    begin
                            for(integer k=0;k<4;++k)//See if Other Lifts are near them by calculating hop count
                            begin
                                KL[3]=L[k];
                                if(KL[3][i]==1)
                                begin
                                    if(D[k]==1 || D[k]==0)//If other one moves in same direction or is at rest
                                    begin
                                        if(i>=S[k])//Going towards it so calculate hop count
                                        begin
                                            H[k]=i-S[k];
                                        end
                                        else//already crossed the floor set to high
                                        begin
                                            H[k]=10;
                                        end
                                    end
                                    else if(D[k]==2)//If other one moves in opposite direction or is at rest
                                    begin
                                        if(i>S[k])//already crossed the floor set to high
                                        begin
                                            H[k]=10;
                                        end
                                        else//Going towards it so calculate hop count
                                        begin
                                            H[k]=S[k]-i;
                                            for(integer p=S[k]+1;p<10;++p)//If there are other requests to this lift at top of other states then set high hop count
                                            begin
                                                if(L[3][p]==1)
                                                    H[k]=10;
                                            end
                                        end
                                    end
                                end
                                else
                                    H[k]=10;
                            end
                            DFlag[3]=0;
                            for(integer k=0;k<4;++k)//Change Direction if other lifts can service the top floors earlier than this.
                            begin
                                if(H[k]<H[3])
                                    DFlag[3]=1;
                            end
                            if(DFlag[3]==1)//Changes
                                D[3]=2;
                            else//Remains Same
                                D[3]=1;
                    end
                    else//If no request at top exists
                    begin
                        if(L[3]==0)//If no requests at bottom also
                            D[3]=0;
                        else
                            D[3]=2;
                    end

                    //Get what state to go next
                    if(D[3]==1)
                        R[3]=i;
                    else if(D[3]==2)
                    begin
                        for(r=S[3]-1;r!=-1 && L[3][r]==0;--r);//Finds Nearest Bottom Request
                        R[3]=r;
                        if(R[3]==15)//Boundary Condition When lift is at the least floor
                        begin
                            D[3]=1;
                            R[3]=i;
                        end
                    end
                end
                else if(D[3]==2 || Flag[3]==0)//if currently going down
                begin

                    //Finding if any requests are there below, if any the nearest is obtained in 'i'
                    i=S[3]-1;
                    while(i!=-1 && L[3][i]==0)//See if bottom floors requested
                    begin
                        i=i-1;
                    end

                    if(i!=-1)//Yes at bottom floor someone requested
                    begin   
                            for(integer k=0;k<4;++k)//See if Other Lifts are near them by calculating hop count
                            begin
                                KL[3]=L[k];
                                if(KL[3][i]==1)
                                    begin
                                    if(D[k]==2 || D[k]==0)//If other one moves in same direction or is at rest
                                    begin
                                        if(i<=S[k])//Going towards it so calculate hop count
                                        begin
                                            H[k]=S[k]-i;
                                        end
                                        else//already crossed the floor set to high
                                        begin
                                            H[k]=10;
                                        end
                                    end
                                    else if(D[k]==1)//If other one moves in opposite direction or is at rest
                                    begin
                                        if(i<S[k])//already crossed the floor set to high
                                        begin
                                            H[k]=10;
                                        end
                                        else//Going towards it so calculate hop count
                                        begin
                                            H[k]=i-S[k];
                                            for(integer p=S[k]-1;p>0;--p)//If there are other requests to this lift at bottom of other states then set high hop count
                                            begin
                                                if(L[3][p]==1)
                                                    H[k]=10;
                                            end
                                        end
                                    end
                                    end
                                else
                                    H[k]=10;
                            end

                            DFlag[3]=0;
                            for(integer k=0;k<4;++k)//Change Direction if other lifts can service the bottom floors earlier than this.
                            begin
                                if(H[k]<H[3])
                                    DFlag[3]=1;
                            end
                            if(DFlag[3]==1)//Changes
                                D[3]=1;
                            else//Remains Same
                                D[3]=2;
                    end
                    else//If no request at bottom exists
                    begin
                        if(L[3]==0)//If no requests at top also
                            D[3]=0;
                        else
                            D[3]=1;
                    end

                    //Get what state to go next
                    if(D[3]==2)
                        R[3]=i;
                    else if(D[3]==1)
                    begin
                        for(r=S[3]+1;r<10 && L[3][r]==0;++r);//Finds Nearest Top Request
                        R[3]=r;
                        if(R[3]==10)//Boundary Condition When lift is at the Top most floor
                        begin
                            D[3]=2;
                            R[3]=i;
                        end
                    end
                end
            end

            //Direction Decided
            if(D[3]==1)//Go Up
            begin
                S[3]=S[3]+1;
                #1;
            end
            else if(D[3]==2)//Go Down
            begin
                S[3]=S[3]-1;
                #1;
            end
            else//Stop
            begin
                #1;
            end
        end
    end
endmodule

module LFT_tb;
    reg[11:0] Inp;

    LFT lft(Inp);

    initial
    begin
        $display("'+' : Requested\n'-' : Not-Requested\n'^' : Going-up-towards-it\n'v' : Going-down-towards-it\n'[]' : Lift-Open\n'I' : Lift-at-Rest");
        #10 Inp=12'b000000110010; 
        #1  Inp=12'b010010010010;
        #1  Inp=12'b010100000010;
        #1  Inp=12'b000100000001;
        #1  Inp=12'b100100010000;
        #1  Inp=12'b110101010010;
        #1  Inp=12'b100000000001;
        #1  Inp=12'b110000000001;
    end
endmodule