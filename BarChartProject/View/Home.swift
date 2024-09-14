//
//  Home.swift
//  ChartPractice
//
//  Created by Muhammad Zeeshan on 09/08/2024.
//

import SwiftUI
import Charts

struct Home: View {
    //MARK: State Chart Data for Animation Changes
    @State var sampleAnalystic: [SiteView] = sample_analytics
    //MARK: View Properties
    @State var currrentTab: String = "D"
    // MARK: Gesture Properties
    @State var currentActiveItem: SiteView?
    @State var plotWidth: CGFloat = 0
    
    var body: some View {
        NavigationStack {
    
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        let totalValue = sampleAnalystic.reduce(0.0) { partialResult, item in
                            item.views + partialResult
                        }
                        
                        Text(totalValue.stringFormat)
                            .font(.largeTitle.bold())
                        
                        Picker(" ", selection: $currrentTab) {
                            Text("D").tag("D")
                            Text("W").tag("W")
                            Text("M").tag("M")
                        }
                        .pickerStyle(.segmented)
                        .padding(.leading, 80)
                    }
                    // MARK: Graph layer
                    ChartView()
                }
                .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .navigationTitle("Personal")
            // MARK: Simply Updating values For segmanted Tabs
            .onChange(of: currrentTab) {
                let newValue = currrentTab
                sampleAnalystic = sample_analytics
                if newValue != "7 Days" {
                    for (index,_) in sampleAnalystic.enumerated() {
                        sampleAnalystic[index].views = .random(in: 10000...1000000)
                    }
                }
//                 MARK: Re-Animating view
                animateGraph(fromChange: true)
            }
        }
    }
    
    @ViewBuilder
    func ChartView() -> some View {
        let max = sampleAnalystic.max { item1, item2 in
            return item2.views > item1.views
        }?.views ?? 10
        
        Chart {
            ForEach(sampleAnalystic) { item in
                // MARK: Bars of Graph
                // MARK: Animating Graph
                BarMark(
                    x: .value("Hour", item.hour, unit: .hour),
                    y: .value("Views", item.animate ? item.views : 0)
                )
                .foregroundStyle(Color.blue.gradient)
                
                // MARK: Rule Mark for Currently Dragging Item
                if let currentActiveItem,currentActiveItem.id == item.id {
                    RuleMark(x: .value("Hour", currentActiveItem.hour))
                    // Goted Style
                        .lineStyle(.init(lineWidth: 2, miterLimit: 2, dash: [10], dashPhase: 5))
                    // MARK: Setting in Middle of Each Bars
                        .offset(x: (plotWidth / CGFloat(sampleAnalystic.count)) / 2)
                        .annotation(position: .automatic) {
                            VStack {
                                Text("Expense")
                                    .font(.caption)
                                    .foregroundStyle(Color.gray)
                                Text(currentActiveItem.views.stringFormat)
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.white.shadow(.drop(radius: 2)))
                            )
                        }
                }
            }
        }
        // MARK: Customizing Y-Axis Length
        .chartYScale(domain: 1500...(max + 1000000))
        // MARK: Gesture To Highlight Current Bar
        .chartOverlay(content: { proxy in
            GeometryReader { innerProxy in
                Rectangle()
                    .fill(Color.clear).contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged{ value in
                                // MARK: Geting Current Location
                                let Location = value.location
                                // Extracting Value From The Location
                                // Swift Charts Gives The Direct Ability to do that
                                // we're going to extract the Data in A-Axis Then with the help of That Date Value we're extracting the current Item
                                if let date: Date = proxy.value(atX: Location.x){
                                    // Extracting Hour
                                    let calender = Calendar.current
                                    let hour = calender.component(.hour, from: date)
                                    
                                    if let currentItem = sampleAnalystic.first(where: { item in
                                        calender.component(.hour, from: item.hour) == hour
                                    }) {
                                        self.currentActiveItem = currentItem
                                        self.plotWidth = proxy.plotSize.width
                                    }
                                }
                                
                            }.onEnded({ value in
                                self.currentActiveItem = nil
                            })
                    )
            }
        })
        .frame(height: 250)
        .onAppear {
            animateGraph()
        }
    }
    
    // MARK: Animate Graph
    func animateGraph(fromChange: Bool = false ) {
        for (index, _) in sampleAnalystic.enumerated() {
            
            withAnimation(fromChange ? .easeInOut(duration: 0.8) : .interactiveSpring(response: 0.8, dampingFraction: 0.8)) {
                sampleAnalystic[index].animate = true
            }
            
        }
    }
}

#Preview {
    Home()
}


// MARK: Extension to Convert Double to String with K,M Number Values
// EG: 10K, 10M,...etc
extension Double {
    var stringFormat: String {
        if self >= 1000 && self < 1000000 {
            return String(format: "%.1fK", self / 1000).replacingOccurrences(of: ".0", with: "")
        }
        
        if self >= 1000000 {
            return String(format: "%.1fM", self / 999999).replacingOccurrences(of: ".0", with: "")
        }
        
        return String(format: "%.0f", self)
    }
}
