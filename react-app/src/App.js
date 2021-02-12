import AleaiactaComp from './AleaiactaComp';

function App() {
  return (
    <div className="App">
      <header className="App-header">
        <AleaiactaComp
          sz={5}
          seed={Math.floor(Math.random()*0xFFFFFFFF)}
          goalScore={150}
          goalChains={15}
        />
      </header>
    </div>
  );
}

export default App;
